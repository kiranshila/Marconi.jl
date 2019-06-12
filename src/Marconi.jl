module Marconi
using PGFPlotsX

 # Network Params
include("NetworkParameters.jl")

# Package exports
export readTouchstone
export plotSmith
export plotSmith!
export plotSmithCircle!

"""
The base Network type for representing n-port linear networks with characteristic impedance Z0.
  By default, the network is stored as S-Parameters with the corresponding frequency list.
"""
mutable struct Network
  ports::Int
  Z0::Union{Real,Complex}
  frequency::Array{Real,1}
  s_params::Array{Array{Union{Real,Complex},2},1}
  passive::Bool
  reciprocal::Bool
end

# File option enums
@enum paramType S Y Z G H
@enum paramFormat MA DB RI

"""
    readTouchstone("myFile.sNp")

Reads the contents of `myFile.sNp` into a Network object.
This will convert all file types to S-Parameters, Real/Imaginary

Currently does not support reference lines (Different port impedances) or noise parameters
"""
function readTouchstone(filename::String)
  # File option settings - defaults
  thisfreqExponent = 1e9
  thisParamType = S
  thisParamFormat = MA
  thisZ0 = 50.

  # Setup blank network object to build from
  thisNetwork = Network(0,0,[],[],false,false)

  # Open the file
  open(filename) do f
    while !eof(f)
      line = readline(f)
      if line[1] == '!' # Ignore comment lines
        continue
      elseif line[1] == '#' # Parse option line
        # Option line contains [HZ/KHZ/MHZ/GHZ] [S/Y/Z/G/H] [MA/DB/RI] [R n]
        # Or contains nothing implying GHZ S MA R 50
        options = line[2:end]
        if length(options) == 0
          continue # Use defaults
        else
          options = split(strip(options)," ")
          # Some VNAs put random amounts of spaces between the options,
          # so we have to remove all the empty entries
          options = [option for option in options if option != ""]

          # Process frequency exponent
          if options[1] == "HZ"
            thisfreqExponent = 1.
          elseif options[1] == "KHZ"
            thisfreqExponent = 1e3
          elseif options[1] == "MHZ"
            thisfreqExponent = 1e6
          elseif options[1] == "GHZ"
            thisfreqExponent = 1e9
          end

          # Process Parameter Type
          if options[2] == "S"
            thisParamType = S
          elseif options[2] == "Y"
            thisParamType = Y
          elseif options[2] == "Z"
            thisParamType = Z
          elseif options[2] == "G"
            thisParamType = G
          elseif options[2] == "H"
            thisParamType = H
          end

          # Process Parameter Format
          if options[3] == "MA"
            thisParamFormat = MA
          elseif options[3] == "DB"
            thisParamFormat = DB
          elseif options[3] == "RI"
            thisParamFormat = RI
          end

          # Process Z0
          thisZ0 = parse(Float64,options[5])
        end
      else # Process everything else
        freq, ports, params = processTouchstoneLine(line,thisfreqExponent,thisParamType,thisParamFormat,thisZ0)
        thisNetwork.ports = ports
        thisNetwork.Z0 = thisZ0
        push!(thisNetwork.frequency,freq)
        push!(thisNetwork.s_params,params)
      end
    end
  end

  # Checks for passivisity and recipocity
  thisNetwork.passive = isPassive(thisNetwork)
  thisNetwork.reciprocal = isReciprocal(thisNetwork)

  # Return the constructed network
  return thisNetwork
end

"Internal function to process touchstone lines"
function processTouchstoneLine(line::String,freqExp::Real,paramT::paramType,paramF::paramFormat,Z0::T) where {T <: Number}
  lineParts = [data for data in split(line," ") if data != ""]
  frequency = parse(Float64,lineParts[1]) * freqExp
  ports = √((length(lineParts)-1)/2) # Parameters are in two parts for each port
  if mod(ports,1) != 0
    throw(DimensionMismatch("Parameters in file are not square, somethings up"))
  end
  ports = floor(Int,ports) # It needs to be an Int anyway

  # Step 1, get the parameters into RI format as that's what we will use
  params = zeros(Complex,ports,ports)
  for i = 2:2:(ports*ports*2) # Skip frequency
    # There will be ports*ports number of parameters
    paramIndex = floor(Int,i/2)
    if paramF == RI # Real Imaginary
      # Do nothing, already in the right type
      params[paramIndex] = parse(Float64,lineParts[i]) + 1.0im * parse(Float64,lineParts[i+1])
    elseif paramF == MA # Magnitude Angle(Degrees)
      mag = parse(Float64,lineParts[i])
      angle = parse(Float64,lineParts[i+1])
      params[paramIndex] = mag  * cosd(angle) +
                           1.0im * mag  * sind(angle)
    elseif paramF == DB # dB Angle
      mag = 10^(parse(Float64,lineParts[i])/20)
      angle = parse(Float64,lineParts[i+1])
      params[paramIndex] = mag  * cosd(angle) +
                           1.0im * mag  * sind(angle)
    end
  end

  # Step 2, convert into S-Parameters
  if paramT == S
    # Do nothing, they are already S
  elseif paramT == Z
    params = z2s(params,Z0=Z0)
  elseif paramT == Y
    params = y2s(params,Z0=Z0)
  end # TODO H and G Parameters

  return frequency,ports,params
end

"Internal function to check for pasivisity"
function isPassive(network::Network)
  for parameter in network.s_params
    for s in parameter
      if abs(s) > 1
        return false
      end
    end
  end
  # If we got through everything, then it's passive
  return true
end

"Internal function to check for recipocity"
function isReciprocal(network::Network)
  #FIXME
  return true
end

"""
    plotSmith(network,(1,1))

Plots the S(1,1) parameter from `network` on a Smith Chart.

Returns a `PGFPlotsX.SmithChart` object.
"""
function plotSmith(network::Network,parameter::Tuple{Int,Int};
                  axopts::PGFPlotsX.Options = @pgf({}),
                  pltopts::PGFPlotsX.Options = @pgf({}))
  # Collect the data we want
  data = [s[parameter[1],parameter[2]] for s in network.s_params]
  # Convert to normalized input impedance
  data = [(1+datum)/(1-datum) for datum in data]
  # Split into coordinates
  data = [(real(z),imag(z)) for z in data]
  # Create the PGFslotsX axis
  p = @pgf SmithChart({axopts...},Plot({pltopts...},Coordinates(data)))
  # Draw on smith chart
  return p
end

"""
    plotSmith!(sc, network,(1,1))

Plots the S(1,1) parameter from `network` on an existing Smith Chart `sc`

Returns the `sc` object
"""
function plotSmith!(smith::SmithChart,network::Network,parameter::Tuple{Int,Int};
                    pltopts::PGFPlotsX.Options = @pgf({}))
  # Collect the data we want
  data = [s[parameter[1],parameter[2]] for s in network.s_params]
  # Convert to normalized input impedance
  data = [(1+datum)/(1-datum) for datum in data]
  # Split into coordinates
  data = [(real(z),imag(z)) for z in data]
  push!(smith,@pgf Plot({pltopts...},Coordinates(data)))
  return smith
end

"""
    plotSmithCircle!(sc, xc, yc, rad)

Plots a cricle with center coordinates `(xc,yc)` on the ``\\Gamma`` plane with radius rad
on an existing Smith Chart object.

Returns the `sc` object
"""
function plotSmithCircle!(smith::SmithChart,xc::A,yc::B,rad::C;
                          opts::PGFPlotsX.Options = @pgf({})) where {A <: Real, B <: Real, C <: Real}
  # Create an array to represent the circle
  x = [rad*cosd(v) for v = -180:180]
  y = [rad*sind(v) for v = -180:180]

  circle = @pgf Plot({"is smithchart cs", opts...},Coordinates(x.+xc,y.+yc))
  push!(smith,circle)
  return smith
end

end # Module End
