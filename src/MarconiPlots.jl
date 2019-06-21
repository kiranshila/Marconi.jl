using PGFPlotsX

export plotSStabCircle!
export plotLStabCircle!
export plotVSWR!
export plotSmithData
export plotSmithData!
export plotSmithCircle!
export plotRectangular
export plotRectangular!
export dB

"""
    plotSmithData(network,(1,1))

Plots the S(1,1) parameter from `network` on a Smith Chart.

Returns a `PGFPlotsX.SmithChart` object.
"""
function plotSmithData(network::T,parameter::Tuple{Int,Int};
                  axopts::PGFPlotsX.Options = @pgf({}),
                  opts::PGFPlotsX.Options = @pgf({}),
                  freqs::Union{StepRangeLen,Array, Nothing} = nothing,
                  label::Union{String,Nothing} = nothing) where {T <: AbstractNetwork}
  # Check that data is in bounds
  if parameter[1] > network.ports || parameter[1] < 1
    throw(DomainError(parameter[1], "Dimension 1 Out of Bounds"))
  end
  if parameter[2] > network.ports || parameter[2] < 1
    throw(DomainError(parameter[1], "Dimension 2 Out of Bounds"))
  end
  if T == DataNetwork
    # Collect the data we want
    data = [s[parameter[1],parameter[2]] for s in network.s_params]
    # Convert to normalized input impedance
    data = [(1+datum)/(1-datum) for datum in data]
    # Split into coordinates
    data = [(real(z),imag(z)) for z in data]
    # Create the PGFslotsX axis
    if label != nothing
      p = @pgf SmithChart({axopts...},PlotInc({mark = "none", opts...},Coordinates(data)),LegendEntry(label))
    else
      p = @pgf SmithChart({axopts...},PlotInc({mark = "none", opts...},Coordinates(data)))
    end
    # Draw on smith chart
    return p
  elseif T == EquationNetwork
    # Grab s-parameter data for each frequency
    data = [network.eq(freq=x,Z0=network.Z0) for x in freqs]
    # Convert to normalized input impedance
    data = [(1+datum)/(1-datum) for datum in data]
    # Add smith chart data
    data = [(real(z),imag(z)) for z in data]
    # Create the PGFslotsX axis
    if label != nothing
      p = @pgf SmithChart({axopts...},PlotInc({mark = "none", opts...},Coordinates(data)),LegendEntry(label))
    else
      p = @pgf SmithChart({axopts...},PlotInc({mark = "none", opts...},Coordinates(data)))
    end
    # Draw on smith chart
    return p
  end
end

"""
    plotSmithData!(sc, network,(1,1))

Plots the S(1,1) parameter from `network` on an existing Smith Chart `sc`

Returns the `sc` object
"""
function plotSmithData!(smith::SmithChart, network::T,parameter::Tuple{Int,Int};
                  axopts::PGFPlotsX.Options = @pgf({}),
                  opts::PGFPlotsX.Options = @pgf({}),
                  freqs::Union{StepRangeLen,Array, Nothing} = nothing,
                  label::Union{String,Nothing} = nothing) where {T <: AbstractNetwork}
  # Check to see if data is in bounds
  if parameter[1] > network.ports || parameter[1] < 1
    throw(DomainError(parameter[1], "Dimension 1 Out of Bounds"))
  end
  if parameter[2] > network.ports || parameter[2] < 1
    throw(DomainError(parameter[1], "Dimension 2 Out of Bounds"))
  end
  # Collect the data we want
  data = [s[parameter[1],parameter[2]] for s in network.s_params]
  # Convert to normalized input impedance
  data = [(1+datum)/(1-datum) for datum in data]
  # Split into coordinates
  data = [(real(z),imag(z)) for z in data]
  push!(smith,@pgf PlotInc({mark = "none", opts...},Coordinates(data)))
  if label != nothing
    push!(smith,@pgf(LegendEntry(label)))
  end
  return smith
end

"""
    plotSmithCircle!(sc, xc, yc, rad)

Plots a cricle with center coordinates `(xc,yc)` on the ``\\Gamma`` plane with radius rad
on an existing Smith Chart object.

Returns the `sc` object
"""
function plotSmithCircle!(smith::SmithChart,xc::A,yc::B,rad::C;
                          opts::PGFPlotsX.Options = @pgf({}),
                          label::Union{String,Nothing} = nothing) where {A <: Real, B <: Real, C <: Real}
  # Create an array to represent the circle
  x = [rad*cosd(v) for v = -180:180]
  y = [rad*sind(v) for v = -180:180]

  circle = @pgf PlotInc({"is smithchart cs",mark="none", opts...},Coordinates(x.+xc,y.+yc))
  push!(smith,circle)
  if label != nothing
    push!(smith,@pgf(LegendEntry(label)))
  end
  return smith
end

dB(x::T) where {T <: Real} = 20*log10(x)
dB(x::T) where {T <: Complex} = 20*log10(abs(x))

function plotRectangular(network::T,
                         parameter::Tuple{Int,Int},
                         pltFunc::Function = dB,
                         paramFormat::paramType = S;
                         axopts::PGFPlotsX.Options = @pgf({}),
                         opts::PGFPlotsX.Options = @pgf({}),
                         freqs::Union{StepRangeLen,Array, Nothing} = nothing,
                         label::Union{String,Nothing} = nothing) where {T <: AbstractNetwork}
  # Check that data is in bounds
  if parameter[1] > network.ports || parameter[1] < 1
    throw(DomainError(parameter[1], "Dimension 1 Out of Bounds"))
  end
  if parameter[2] > network.ports || parameter[2] < 1
    throw(DomainError(parameter[1], "Dimension 2 Out of Bounds"))
  end
  if T == DataNetwork
    # Convert parameter
    if paramFormat == S
      # Do nothing
      data = network.s_params
    elseif paramFormat == Y
      data = s2y(network.s_params, Z0 = network.Z0)
    elseif paramFormat == Z
      data = s2z(network.s_params, Z0 = network.Z0)
    elseif paramFormat == G
      data = s2g(network.s_params, Z0 = network.Z0)
    elseif paramFormat == H
      data = s2h(network.s_params, Z0 = network.Z0)
    end

    # Collect the data we want
    data = [d[parameter[1],parameter[2]] for d in data]

    # Apply plotting function
    data = [pltFunc(num) for num in data]

    # Find frequency multiplier from the last element
    multiplierString = ""
    multiplier = 1
    freq = network.frequency[end]
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

    frequency = network.frequency ./ multiplier

    # Format with freq
    data = [(frequency[i],data[i]) for i = 1:length(data)]

    xlabel = "Frequency ($(multiplierString)Hz)"

    # Create the PGFslotsX axis
    if label != nothing
      p = @pgf Axis({xlabel=xlabel, axopts...},PlotInc({opts...},Coordinates(data)),LegendEntry(label))
      return p
    else
      p = @pgf Axis({xlabel=xlabel, axopts...},PlotInc({opts...},Coordinates(data)))
      return p
    end
  elseif T == EquationNetwork
    # FIXME
  end
end

function plotRectangular(network::T,
                         pltFunc::Function;
                         axopts::PGFPlotsX.Options = @pgf({}),
                         opts::PGFPlotsX.Options = @pgf({}),
                         freqs::Union{StepRangeLen,Array, Nothing} = nothing,
                         label::Union{String,Nothing} = nothing) where {T <: AbstractNetwork}
  if T == DataNetwork
    # Apply plotting function
    data = pltFunc(network)

    # Find frequency multiplier from the last element
    multiplierString = ""
    multiplier = 1
    freq = network.frequency[end]
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

    frequency = network.frequency ./ multiplier

    # Format with freq
    data = [(frequency[i],data[i]) for i = 1:length(data)]

    xlabel = "Frequency ($(multiplierString)Hz)"

    # Create the PGFslotsX axis
    if label != nothing
      p = @pgf Axis({xlabel=xlabel, axopts...},PlotInc({mark = "none", opts...},Coordinates(data)),LegendEntry(label))
    else
      p = @pgf Axis({xlabel=xlabel, axopts...},PlotInc({mark = "none", opts...},Coordinates(data)))
    end
    # Draw on rectangular axis
    return p
  elseif T == EquationNetwork
    # FIXME
  end
end

function plotRectangular!(ax::Axis,
                          network::T,
                          pltFunc::Function;
                          axopts::PGFPlotsX.Options = @pgf({}),
                          opts::PGFPlotsX.Options = @pgf({}),
                          freqs::Union{StepRangeLen,Array, Nothing} = nothing,
                          label::Union{String,Nothing} = nothing) where {T <: AbstractNetwork}
  if T == DataNetwork
    # Apply plotting function
    data = pltFunc(network)

    # Create y label
    ylabel = "$(pltFunc)"

    # Find frequency multiplier from the last element
    multiplierString = ""
    multiplier = 1
    freq = network.frequency[end]
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

    frequency = network.frequency ./ multiplier

    # Format with freq
    data = [(frequency[i],data[i]) for i = 1:length(data)]

    xlabel = "Frequency ($(multiplierString)Hz)"

    # Create the PGFslotsX plot
    if label != nothing
      plt = @pgf PlotInc({mark = "none", opts...},Coordinates(data))
      push!(ax,plt)
      push!(ax,@pgf(LegendEntry(label)))
    else
      plt = @pgf PlotInc({mark = "none", opts...},Coordinates(data))
      push!(ax,plt)
    end
    # Draw on rectangular axis
    return ax
  elseif T == EquationNetwork
    # FIXME
  end
end

function plotRectangular!(ax::Axis,
                          network::T,
                          parameter::Tuple{Int,Int},
                          pltFunc::Function = dB,
                          paramFormat::paramType = S;
                          opts::PGFPlotsX.Options = @pgf({}),
                          freqs::Union{StepRangeLen,Array, Nothing} = nothing,
                          label::Union{String,Nothing} = nothing) where {T <: AbstractNetwork}
  # Check that data is in bounds
  if parameter[1] > network.ports || parameter[1] < 1
    throw(DomainError(parameter[1], "Dimension 1 Out of Bounds"))
  end
  if parameter[2] > network.ports || parameter[2] < 1
    throw(DomainError(parameter[1], "Dimension 2 Out of Bounds"))
  end
  if T == DataNetwork
    # Convert parameter
    if paramFormat == S
      # Do nothing
      data = network.s_params
    elseif paramFormat == Y
      data = s2y(network.s_params, Z0 = network.Z0)
    elseif paramFormat == Z
      data = s2z(network.s_params, Z0 = network.Z0)
    elseif paramFormat == G
      data = s2g(network.s_params, Z0 = network.Z0)
    elseif paramFormat == H
      data = s2h(network.s_params, Z0 = network.Z0)
    end

    # Collect the data we want
    data = [d[parameter[1],parameter[2]] for d in data]

    # Apply plotting function
    data = [pltFunc(num) for num in data]

    # Find frequency multiplier from the last element
    multiplierString = ""
    multiplier = 1
    freq = network.frequency[end]
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

    frequency = network.frequency ./ multiplier

    # Format with freq
    data = [(frequency[i],data[i]) for i = 1:length(data)]

    xlabel = "Frequency ($(multiplierString)Hz)"

    # Create the PGFslotsX plot
    plt = @pgf PlotInc({opts...},Coordinates(data))

    # Push to axis
    push!(ax,plt)
    if label != nothing
      push!(ax,@pgf(LegendEntry(label)))
    end
    # Draw on rectangular axis
    return ax
  elseif T == EquationNetwork
    # FIXME
  end
end

"""
    plotVSWR!(sc,VSWR)

Plots the circle that represents a VSWR of `VSWR` onto an existing Smith Chart.
"""
function plotVSWR!(sc::SmithChart,VSWR::Real;opts::PGFPlotsX.Options = @pgf({}),label::Union{String,Nothing} = nothing)
  Γ = (VSWR-1)/(VSWR+1)
  return plotSmithCircle!(sc,0,0,Γ,opts=opts,label=label)
end

"""
    plotSStabCircle!(sc,network,freq)

Plots the the source stability circle on Smith Chart `sc` from `network` at frequency `freq`.
"""
function plotSStabCircle!(sc::SmithChart,network::T,freq::Real;
                          opts::PGFPlotsX.Options = @pgf({}),label::Union{String,Nothing} = nothing) where {T <: AbstractNetwork}
  # Grab S-Params at the requested frequency
  position = findall(x->x==freq, network.frequency)[1] # There should only be one
  @assert position != nothing "Frequency not found in frequency list"
  s = network.s_params[position]
  rs = abs((s[1,2]*s[2,1]) / (abs(s[1,1])^2 - testMagDelta(network,pos = position)^2))
  Cs = conj(s[1,1] - testDelta(network,pos = position) * conj(s[2,2])) /
       (abs(s[1,1])^2 - testMagDelta(network,pos = position)^2)
  plotSmithCircle!(sc,real(Cs),imag(Cs),rs,opts=opts,label=label)
end

"""
    plotLStabCircle!(sc,network,freq)

Plots the the load stability circle on Smith Chart `sc` from `network` at frequency `freq`.
"""
function plotLStabCircle!(sc::SmithChart,network::T,freq::Real;
                          opts::PGFPlotsX.Options = @pgf({}),label::Union{String,Nothing} = nothing) where {T <: AbstractNetwork}
  # Grab S-Params at the requested frequency
  position = findall(x->x==freq, network.frequency)[1] # There should only be one
  @assert position != nothing "Frequency not found in frequency list"
  s = network.s_params[position]
  rs = abs((s[1,2]*s[2,1]) / (abs(s[2,2])^2 - testMagDelta(network,pos = position)^2))
  Cs = conj(s[2,2] - testDelta(network,pos = position) * conj(s[1,1])) /
       (abs(s[2,2])^2 - testMagDelta(network,pos = position)^2)
  plotSmithCircle!(sc,real(Cs),imag(Cs),rs,opts=opts,label=label)
end
