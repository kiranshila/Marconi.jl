module Marconi

import Base.show
import Base.==
import Base.+
import Base.findmax
import Base.findmin
using LinearAlgebra
using Interpolations
using Printf
using CSV

# Package exports
export readTouchstone
export writeTouchstone
export isPassive
export isReciprocal
export AbstractNetwork
export AbstractRadiatonPattern
export DataNetwork
export EquationNetwork
export testΔ
export testMagΔ
export testK
export testμ
export testMUG
export testMSG
export testMAG
export ∠
export inputZ
export Γ
export interpolate
export complex2angleString
export equationToDataNetwork
export mapView3

include("Constants.jl")
include("NetworkParameters.jl") # Needed here for touchstone conversion

abstract type AbstractNetwork end

"""
The base Network type for representing n-port linear networks with characteristic impedance Z0.
  By default, the network is stored as S-Parameters with the corresponding frequency list.
"""
mutable struct DataNetwork <: AbstractNetwork
  ports::Int
  Z0::Number
  frequency::Array{Real,1}
  s_params::Union{Array{Number,3},Nothing}
end

function ==(a::DataNetwork,b::DataNetwork)
  a.ports == b.ports &&
  a.Z0 == b.Z0 &&
  a.frequency == b.frequency &&
  a.s_params == b.s_params
end

"""
        mapView3(f,A)
Returns a vector that is the result of mapping f on slices of A down dimension 3. =
"""
function mapView3(f,A)
  @assert length(size(A)) == 3 "A must be three dimensional"
  @views [f(A[:,:,i]) for i in 1:size(A,3)]
end

"""
The base Network type for representing n-port linear networks with characteristic impedance Z0.
  The S-Parameters for an EquationNetwork are defined by a function that returns a `ports`-square matrix
  and accepts kwargs `Z0` and `freq`. Please provide default arguments for any input parameters.
"""
mutable struct EquationNetwork <: AbstractNetwork
  ports::Int
  Z0::Union{Real,Complex}
  eq::Function
  function EquationNetwork(ports,Z0,eq)
    # Test that the equation is valid by checking size and args
    result = eq(freq = 1,Z0 = Z0)
    if ports == 1
      @assert size(result) == () "1-Port network must be built with a function that returns a single number."
    else
      @assert size(result) == (ports,ports) "n-Port network must be built with a function that returns an n-square matrix."
    end
    new(ports,Z0,eq)
  end
end

"""
    equationToDataNetwork(equationNet,args=(arg1,arg2),freqs=[1,2,3])
Utility function to convert an equation network to a data network by evaluating it at every frequency in the list
or range `freqs`.
"""
function equationToDataNetwork(network;args=(),freqs)
  DataNetwork(network.ports,network.Z0,Array(freqs),[network.eq(args...,Z0=network.Z0,freq = f) for f in freqs])
end

function Base.show(io::IO,network::AbstractNetwork)
  if T == DataNetwork
    println(io,"$(network.ports)-Port Network")
    println(io," Z0 = $(network.Z0)")
    println(io," Frequency = $(prettyPrintFrequency(network.frequency[1])) to $(prettyPrintFrequency(network.frequency[end]))")
    println(io," Points = $(length(network.frequency))")
  elseif T == EquationNetwork
    println(io,"$(network.ports)-Port Network")
    println(io," Z0 = $(network.Z0)")
    println(io," Equation-driven Network")
  end
end

function prettyPrintFrequency(freq)
  multiplierString = ""
  multiplier = 1
  if freq < 1e3
    multiplierString = ""
    multiplier = 1
  elseif 1e3 <= freq < 1e6
    multiplierString = "K"
    multiplier = 1e3
  elseif 1e6 <= freq < 1e9
    multiplierString = "M"
    multiplier = 1e6
  elseif 1e9 <= freq < 1e12
    multiplierString = "G"
    multiplier = 1e9
  elseif 1e12 <= freq < 1e15
    multiplierString = "T"
    multiplier = 1e12
  end
  return "$(freq/multiplier) $(multiplierString)Hz"
end

"""
    readTouchstone("myFile.sNp")

Reads the contents of `myFile.sNp` into an N-Port Network object.
This will convert all file types to S-Parameters, Real/Imaginary internally

Touchstone files must be v1.1 or older

Currently does not support reference lines (Different port impedances) or noise parameters
"""
function readTouchstone(filename)
  freqScale = 1 # Scaling factor for frequencies
  paramFunction = x -> x # Function to transform params
  paramFormat = (r,i) -> complex(r,i) # Function to transform param format, eg db to ri
  # Empty network object to store results, get num ports from file extension
  network = DataNetwork(parse(Int64,filename[end-1]),50.,[],nothing)

  waitForOptions = true
  lastLineNumber = 1 # To keep track for multi-port nonsense
  matrixToFill = nothing # To store the partially constructed matrix for n > 2 port files

  open(filename) do file
    for ln in eachline(file)
        # Ignore comment lines and comments after lines
        line = split(ln,"!")[1]
        if line == ""
          continue # skip lines that start with a comment
        end

        if waitForOptions
          # Parse the option line
          if line[1] == '#'
            options = filter(x->x != "",split(line[2:end]," "))

            # Frequency Scale, Hz is 1, no change needed
            if lowercase(options[1][1]) == 'k'
              freqScale = 1e3
            elseif lowercase(options[1][1]) == 'm'
              freqScale = 1e6
            elseif lowercase(options[1][1]) == 'g'
              freqScale = 1e9
            elseif lowercase(options[1][1]) == 't'
              freqScale = 1e12
            end

            # Parameter Type
            if lowercase(options[2]) == 'y'
              paramFunction = y2s
            elseif lowercase(options[2]) == 'z'
              paramFunction = z2s
            elseif lowercase(options[2]) == 'g'
              paramFunction = g2s
            elseif lowercase(options[2]) == 'h'
              paramFunction = h2s
            end

            # Paramter Format
            if lowercase(options[3][1]) == 'm'
              paramFormat = (m,a) -> ∠(m,a)
            elseif lowercase(options[3][1]) == 'd'
              paramFormat = (d,a) -> ∠(10^(d/20),a)
            end

            # Characteristic Impedance
            network.Z0 = parse(Float64,options[5])

            # Completed options
            waitForOptions = false
          end
          continue
        end

        # Parse every data line
        vals = parse.(Float64,split(line))
        if length(vals) != 0
          # On the first data line, setup the matrix
          if network.s_params == nothing
            network.s_params = Array{Number}(undef, network.ports, network.ports, 0)
          end

          # Now we do different things depending on the number of ports
          if network.ports == 1
            # We don't need to parse lines in weird ways
            push!(network.frequency,vals[1] * freqScale)
            number = paramFormat(vals[2:end] ...) # Reformat number
            number = fill(number,(1,1)) # Reformat to 1x1
            cat!(network.s_params,number,dims=3) # Cat into network object
          elseif network.ports == 2
            # The order is strange, 11 21 12 22
            push!(network.frequency,vals[1] * freqScale)
            one_one = paramFormat(vals[2:3] ...)
            two_one = paramFormat(vals[4:5] ...)
            one_two = paramFormat(vals[6:7] ...)
            two_two = paramFormat(vals[8:9] ...)
            mat = [one_one one_two;two_one two_two]
            network.s_params = cat(network.s_params,mat,dims=3) # Cat into network object
          else
            # Numbers will be in matrix order, with the first row containing the frequency point
            # First row will include the frequency, but the following rows will not
            if lastLineNumber == 1
              # First row, include the frequency
              push!(network.frequency,vals[1] * freqScale)
              # Collect pairs into, well, pairs
              valPairs = collect(Iterators.partition(vals[2:end],2))
              # Map the format function into the pairs of complex numbers
              row = map(x -> paramFormat(x...),valPairs)
              # Fill in first row of matrix, zero out the rest
              matrixToFill = [row' ; zeros(network.ports-1,network.ports)]
              lastLineNumber += 1
            elseif lastLineNumber != 1 && lastLineNumber != network.ports
              # Inbetween rows, just map values, push line number
              valPairs = collect(Iterators.partition(vals,2))
              row = map(x -> paramFormat(x...),valPairs)
              # Fill in first row of matrix
              matrixToFill[lastLineNumber,:] = row'
              lastLineNumber += 1
            elseif lastLineNumber == network.ports
              # Last row, just map values, line number back to 1
              valPairs = collect(Iterators.partition(vals,2))
              row = map(x -> paramFormat(x...),valPairs)
              # Fill in first row of matrix
              matrixToFill[lastLineNumber,:] = row'
              network.s_params = cat(network.s_params,matrixToFill,dims=3) # Cat into network object
              lastLineNumber = 1
            end
          end
        end
    end
  end
  # At this point, the network object is filled, but has the wrong parameter.
  # We have to map the paramFunction to every element
  return network
  network.s_params = map()
end

"""
    writeTouchstone(network,filename)

Writes a Touchstone file from a Marconi network.
"""
function writeTouchstone(network,filename)
  body = "! Generated from Marconi.jl"
  body *= "\n# Hz S RI R 50\n"
  if network.ports == 1
    for i in 1:length(network.frequency)
      body *= "$(network.frequency[i])\t"
      body *= "$(real(network.s_params[1,1,i]))\t"
      body *= "$(imag(network.s_params[1,1,i]))\n"
    end
  elseif network.ports == 2
    for i in 1:length(network.frequency)
      # In the order S11, S21, S12, S22
      body *= "$(network.frequency[i])\t"
      body *= "$(real(network.s_params[1,1,i]))\t"
      body *= "$(imag(network.s_params[1,1,i]))\t"

      body *= "$(real(network.s_params[2,1,i]))\t"
      body *= "$(imag(network.s_params[2,1,i]))\t"

      body *= "$(real(network.s_params[1,2,i]))\t"
      body *= "$(imag(network.s_params[1,2,i]))\t"

      body *= "$(real(network.s_params[2,2,i]))\t"
      body *= "$(imag(network.s_params[2,2,i]))\n"
    end
  elseif network.ports >= 2
    # FIXME
  end
  io = open(filename, "w")
  print(io, body)
  close(io)
end


function isPassive(network)
  # FIXME
  return true
end


function isReciprocal(network)
  # FIXME
  return true
end

function isLossless(network)
  # FIXME
  return true
end

"""
    testΔ(network)

Returns a vector of `Δ`, the determinant of the scattering matrix.
"""
function testΔ(network;pos = 0)
  @assert network.ports == 2 "Stability tests must be performed on two port networks"
  mapView3(det,network.s_params)
end

"""
    testMagΔ(network)

Returns a vector of `|Δ|`, the magnitude of the determinant of the scattering matrix.

It is necessary that |Δ| must be < 1 for a device to be stable.
"""
function testMagΔ(network)
  @assert network.ports == 2 "Stability tests must be performed on two port networks"
  abs.(mapView3(det,network.s_params))
end

"""
    testK(network)

Returns a vector of the magnitude of `K`, the Rollet stability factor.

# Definition

It is necessary that K must be > 1 for a device to be stable, for K defined as:
```math
K = \\frac{1-|S_{11}|^2-|S_{22}|^2+|\\Delta|^2}{2|S_{12}S_{21}|}
```
"""
function testK(network)
  @assert network.ports == 2 "Stability tests must be performed on two port networks"
  magΔ = testMagΔnetwork)
  return @. (1 - abs(network.s_params[1,1,:])^2 - abs(network.s_params[2,2,:])^2 + magΔ^2) /
            (2 * abs(network.s_params[2,1,:] * network.s_params[1,2,:]))
end

"""
    testμ(network)

Returns a vector of the magnitude of `μ`, the μ stability factor[1].

# Definition

The network is unconditionally stable if μ > 1, for μ defined as:

```math
\\mu = \\frac{1-|S_{11}|^2}{|S_{22}-\\Delta S_{11}^{*}| + |S_{12}S_{21}|}
```

[1]: M. L. Edwards and J. H. Sinsky, "A new criterion for linear 2-port stability using a single geometrically derived parameter," in IEEE Transactions on Microwave Theory and Techniques, vol. 40, no. 12, pp. 2303-2311, Dec. 1992. doi: 10.1109/22.179894
"""
function testμ(network)
    @assert network.ports == 2 "Stability tests must be performed on two port networks"
    Δ = testΔ(network)
    return @. (1 - abs(network.s_params[1,1,:])^2) /
              (abs(network.s_params[2,2,:] - Δ * conj(network.s_params[1,1,:])) +
               abs(network.s_params[1,2,:] * network.s_params[2,1,:]))
end

"""
    testMUG(network)

Returns a vector of the maximum unilateral gain of a network.
"""
function testMUG(network)
  @assert network.ports == 2 "Gain calculations must be performed on two port networks"
  return @. abs(network.s_params[2,1,:])^2 /
            ((1-abs(network.s_params[1,1,:])^2) * (1-abs(network.s_params[2,2,:])^2) )
end

"""
    testMSG(network)

Returns a vector of the maximum stable gain of a network.
"""
function testMSG(network)
  @assert network.ports == 2 "Gain calculations must be performed on two port networks"
  return @. abs(network.s_params[2,1,:]) / abs(network.s_params[1,2,:])
end

"""
    testMAG(network)

Returns a vector of the maximum available gain of a network.
"""
function testMAG(network)
  @assert network.ports == 2 "Gain calculations must be performed on two port networks"
  K = testK(network)
  replace!(x -> x <= 1 ? NaN : x, K)
  return @. (1/(K+sqrt(K^2-1))) * (abs(network.s_params[2,1,:])/abs(network.s_params[1,2,:]))
end

"""
    ∠(mag,angle)

A nice compact way of representing phasors. Angle is in degrees.
"""
function ∠(a,b)
  a*cis(deg2rad(b))
end

"""
    inputZ(Zr,Θ,Z0)

Calculates the input impedance of a lossless transmission line of length `θ` in degrees terminated with `Zr`.
Z0 is optional and defaults to 50.
"""
inputZ(Zr,θ;Z0=50.) = Z0*((Zr+Z0*im*tand(θ))/(Z0+Zr*im*tand(θ)))

"""
    inputZ(Γ,Z0)

Calculates the input impedace from complex reflection coefficient `Γ`.
Z0 is optional and defaults to 50.
"""
inputZ(Γ;Z0=50.) = Z0*(1+Γ)/(1-Γ)

"""
    Γ(Z,Z0)

Calculates the complex reflection coefficient `Γ` from impedance `Z`.
Z0 is optional and defaults to 50.
"""
Γ(Z;Z0=50.) = (Z-Z0)/(Z+Z0)

function complex2angleString(num)
  vals = angle(num) * 180/π
  @sprintf "%.3f∠%.3f°" vals[1] vals[2]
end

function findinrange(ran::StepRange,value)
  return (value-ran.start) ÷ ran.step + 1
end

function findinrange(ran::StepRangeLen,value)
  return (value-ran[1]) ÷ ran.step.hi + 1
end

# Sub files, these need to be at the end here such that the files have access
# to the types defined in this file
include("MarconiPlots.jl")
include("Antennas.jl")
#include("Metamaterials.jl")
end # Module End
