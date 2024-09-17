using POMP
using Distributions
using Random
using DataFrames
using RCall
using Test

dat = include("parus.jl");

rlni = function (;x₀,_...)
    (;x=x₀,)
end

rmeas = function (;x,σₘ,_...)
    d = LogNormal(log(x),σₘ)
    (;y=rand(d),)
end

rproc = function (;t,x,σₚ,r,K,_...)
    s = exp(-r)
    d = LogNormal(s*log(x)+(1-s)*log(K),σₚ)
    (;t=t+1,x=rand(d),)
end

P = pomp(
    dat,
    t0=1960,
    times=:year,
    params=(x₀=0.1,σₘ=0.1,σₚ=0.2,r=0.1,K=1),
    rinit=rlni,
    rmeasure=rmeas,
    rprocess=rproc
);
@test isa(P,POMP.PompObject)

x = rinit(P,nsim=5)
@test size(x)==(5,1)
@test keys(x[1])==(:x,)

y = rmeasure(P,x=x,time=3)
@test size(y)==(5,1,1)
@test keys(y[2])==(:y,)

x = rinit(P,params=[coef(P) for _ = 1:2],nsim=3)
y = rmeasure(P,x=x,params=[coef(P) for _ = 1:2],time=3)
@test size(x)==(3,2)
@test size(y)==(3,2,1)
@test keys(y[2])==(:y,)

coef!(P,(r=0.2,σₘ=0,σₚ=0))
coef(P)
X = rprocess(P,x0=rinit(P));
d = hcat(DataFrame(t=P.time),DataFrame(X))
R"""
library(tidyverse)
$d |>
  mutate(t=unlist(t),x=unlist(x)) |>
  ggplot(aes(x=t,y=x))+
  geom_point()+
  geom_line()+
  theme_bw()
"""
