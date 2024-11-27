# POMP.jl

Summary.

## Package Features

- Implement POMP models.
- Simulate models with process noise and measurement error.
- Particle filters.

## Function Documentation

### Basic constructor

```@docs
pomp
pomp!
```

### Simulation

```@docs
simulate
simulate!
```

### Particle filter

```@docs
pfilter
pfilter!
```

### Workhorses

```@docs
rinit
rinit!
```

```@docs
rmeasure
```

```@docs
rprocess
rprocess!
```

```@docs
logdmeasure
logdmeasure!
```

### Helper functions

```@docs
coef
states
obs
times
timezero
```

### Examples

```@docs
sir
gompertz
```