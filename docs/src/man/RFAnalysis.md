# RF Analysis
```@contents
Pages = ["RFAnalysis.md"]
Depth = 3
```

## The Network Object
Marconi is structured around a base `AbstractNetwork` object. This object can be
constructed with data, equations, and the combination of other networks.

All networks provide attributes `ports` and `Z0` for characteristic impedance.

### DataNetwork
To build a network from a Touchstone file see [File IO](@ref), otherwise we can simply use the constructor for DataNetwork.

Besides `ports` and `Z0`, a `DataNetwork` must also have `frequency`, a vector of frequencies for which the network is characterized,
and `s_params`, for the S-Parameters themselves.

```@example
using Marconi # hide
# DataNetwork(ports,Z0,frequency,s_params)
myNetwork = DataNetwork(1,50,[100e6, 200e6],[0.3+0.5im, 0.4+0.6im])
```

For more than 1 port, the S-Parameters have to be an n-square matrix for n ports.

```@example
using Marconi # hide
myNetwork = DataNetwork(2,50,[100e6, 200e6],[[0.3+0.5im 0.1+0.2im; 0.4+0.6im 0.3+0.5im], [0.3+0.5im 0.1+0.2im; 0.4+0.6im 0.3+0.5im]])
```

### EquationNetwork
To build a network from an equation, we start with an equation that defines some S-Parameters.

Take a series R-L network for example. The S-Parameters of an RL network would look like:

```@example 2
using Marconi # hide
function inductorAndResistor(;freq,Z0)
    L = 1e-9
    R = 30
    z = R + im*2*pi*freq*L
    return (z-Z0)/(z+Z0)
end
```

To use an equation-driven network in Marconi, the function must accept the kwags `freq` and `Z0`.

To build the `EquationNetwork`:

```@example 2
RL = EquationNetwork(1,50,inductorAndResistor)
```

Once again, for n-port networks, the function must provide an n-square matrix

```@example 2
function idealTransmissionLine(;freq,Z0)
    l = 1e-2 # 2cm
    λ = (3e8/freq)
    β = (2*pi)/λ
    return [0 exp(-β*l);exp(-β*l) 0]
end

tline = EquationNetwork(2,50,idealTransmissionLine)
```
