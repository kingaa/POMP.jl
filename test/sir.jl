using POMP
using DataFrames
using Random
using RCall
using Test

@testset verbose=true "SIR model" begin

    Random.seed!(1558102772)

    R"""
library(tidyverse)
library(pomp)

set.seed(1558102772)

simulate(
  t0=0,
  times=seq(1,90,by=1),
  rinit=Csnippet(r"{
    double m = N/(S_0+I_0+R_0);
    S = nearbyint(m*S_0);
    I = nearbyint(m*I_0);
    R = nearbyint(m*R_0);
    C = 0;}"
  ),
  rprocess=euler(
    Csnippet(r"{
    double inf = rbinom(S,1-exp(-Beta*I/N*dt));
    double rcv = rbinom(I,1-exp(-gamma*dt));
    S -= inf;
    I += inf - rcv;
    R += rcv;
    C += rcv;}"
    ),
    delta.t=0.1
  ),
  rmeasure=Csnippet(
    r"{reports = rnbinom(k,k/(k+rho*C));}"
  ),
  dmeasure=Csnippet(
    r"{
      lik = dnbinom(reports,k,k/(k+rho*C),give_log);
    }"
  ),
  obsnames=c("reports"),
  statenames=c("S","I","R","C"),
  paramnames=c(
    "gamma","Beta","k","rho","N",
    "S_0","I_0","R_0"
  ),
  accumvars="C",
  params = c(
    gamma=0.25,rho=0.3,k=10,
    Beta=0.5,N=10000,
    S_0=0.9,I_0=0.01,R_0=0.1
  )
) -> P

P |>
  as.data.frame() |>
  select(time,reports) -> dat

cat("pomp SIR parameters\n")
print(coef(P))

cat("pomp simulation times (SIR)\n")
P |>
  simulate(nsim=1000,format="a") |>
  system.time() |>
  getElement(3) |>
  replicate(n=3) |>
  print()

cat("pomp pfilter times (SIR)\n")
P |>
  pfilter(Np=1000,save.states="unweighted") |>
  system.time() |>
  getElement(3) |>
  replicate(n=3) |>
  print()

cat("pomp likelihood estimate (SIR)\n")
P |>
  pfilter(Np=1000) |>
  logLik() -> ll
ll |>
  round(digits=2) |>
  print()
    """;

    P = sir()
    @test isa(P,POMP.SimPompObject)
    print(P)
    P = pomp(P);
    print(P)

    println("POMP.jl SIR parameters")
    theta = (γ=0.25,ρ=0.3,k=10,β=0.5,N=10000,S₀=0.9,I₀=0.01,R₀=0.1,δt=0.1)
    println(theta)

    println("POMP.jl simulation times (SIR)")
    @time Q = simulate(P,nsim=1000,params=theta)
    @time Q = simulate(Q,nsim=1000)
    simulate!(Q,accumvars=nothing)
    simulate!(Q)
    simulate!(Q)
    @time simulate!(Q,accumvars=(C=0,))
    @time simulate!(Q)
    @time simulate!(Q)
    @time simulate!(Q)
    @time simulate!(Q,nsim=5)

    d1 = melt(Q);

    R"""
library(tidyverse)
$d1 |>
  select(-parset) |>
  pivot_longer(-c(rep,time)) |>
  ggplot(aes(x=time,y=value,group=rep,color=factor(rep)))+
  geom_line()+
  guides(color="none")+
  facet_wrap(~name,scales="free_y")+
  theme_bw()
ggsave(filename="sir-01.png",width=7,height=4)
"""

    @rget dat
    P.data = NamedTuple.(eachrow(select(dat,:reports)));

    println("POMP.jl pfilter times (SIR)")
    @time Pf = pfilter(P,Np=1000,params=theta)
    @time pfilter!(Pf)
    @time pfilter!(Pf)
    @time pfilter!(Pf)

    Pf = pfilter(Pf,Np=1000)
    println("POMP.jl likelihood estimate (SIR)")
    println(round(Pf.logLik,digits=2))

    d2 = melt(Pf)

    R"""
library(tidyverse)
$d2 |>
  pivot_longer(-time) |>
  ggplot(aes(x=time,y=value))+
  geom_line()+
  guides(color="none")+
  facet_wrap(~name,scales="free_y",ncol=1)+
  theme_bw()
ggsave(filename="sir-02.png",width=7,height=4)
"""

end