# RF Analysis
Marconi.jl can calculate simple pasivisity and reciprocity calculations as well
as first principles including but not limited to:
* Rowlett Stability Analysis
* Maximum Gain
* Maximum Stable Gain
* Q-Factor

## Usage
Marconi is structured around a base `Network` object. This object can be
constructed with data, equations, and the combination of other networks.

To build a network from a file, call 
