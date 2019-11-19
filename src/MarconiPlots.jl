using PGFPlotsX
using PlotlyJS

export plotSStabCircle!
export plotLStabCircle!
export plotVSWR!
export plotSmithData
export plotSmithData!
export plotSmithCircle!

# Plotly Stuff
import PlotlyJS.plot # To extend
export plot
export plotPattern2D
export plotPattern3D
export update3DPlot!
export html_plot

"""
    plotSmithData(network,(1,1))

Plots the S(1,1) parameter from `network` on a Smith Chart.

Returns a `PGFPlotsX.SmithChart` object.
"""
function plotSmithData(network::T,parameter::Tuple{Int,Int};
                  axopts::PGFPlotsX.Options = @pgf({}),
                  opts::PGFPlotsX.Options = @pgf({}),
                  freqs::Union{StepRangeLen,Array, Nothing} = nothing,
                  args::Tuple = (),
                  label::Union{String,Nothing} = nothing) where {T <: AbstractNetwork}
  # Check that data is in bounds
  if parameter[1] > network.ports || parameter[1] < 1
    throw(DomainError(parameter[1], "Dimension 1 Out of Bounds"))
  end
  if parameter[2] > network.ports || parameter[2] < 1
    throw(DomainError(parameter[1], "Dimension 2 Out of Bounds"))
  end

  data = nothing

  if T == DataNetwork
    # Collect the data we want
    data = [s[parameter[1],parameter[2]] for s in network.s_params]
  elseif T == EquationNetwork
    # Sample eq at each freq of interest
    @assert freqs != nothing "Freqs must be defined for equation-driven networks"
    data = [network.eq(args...,freq=x,Z0=network.Z0)[parameter[1],parameter[2]] for x in freqs]
  end
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
                  args::Tuple = (),
                  label::Union{String,Nothing} = nothing) where {T <: AbstractNetwork}
  # Check to see if data is in bounds
  if parameter[1] > network.ports || parameter[1] < 1
    throw(DomainError(parameter[1], "Dimension 1 Out of Bounds"))
  end
  if parameter[2] > network.ports || parameter[2] < 1
    throw(DomainError(parameter[1], "Dimension 2 Out of Bounds"))
  end
  data = nothing
  if T == DataNetwork
    # Collect the data we want
    data = [s[parameter[1],parameter[2]] for s in network.s_params]
  elseif T == EquationNetwork
    # Grab s-parameter data for each frequency
    data = [network.eq(args...,freq=x,Z0=network.Z0) for x in freqs]
  end
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

# Utility function for plotting to the docs
function html_plot(p::Union{PlotlyJS.Plot,PlotlyJS.SyncPlot})
    # Generate unique ID for the div
    rng = MersenneTwister(1234)
    uuid = uuid1(rng)
    html = """\n<div id="$(uuid)"></div>
            <script>
                var thediv = document.getElementById('$uuid');
                var plot_json = $(json(p));
                var data = plot_json.data;
                var layout = plot_json.layout;
                Plotly.newPlot(thediv, data, layout, { responsive: true });
            </script>\n"""
    HTML(html)
end


#  =============== Rectangular Plotting Code =============== #

function closestPrefix(num)
  if num >= 1e24
    return 'Y',1e24
  elseif num >= 1e21
    return 'Z',1e21
  elseif num >= 1e18
    return 'E',1e18
  elseif num >= 1e15
    return 'P',1e15
  elseif num >= 1e12
    return 'T',1e12
  elseif num >= 1e9
    return 'G',1e9
  elseif num >= 1e6
    return 'M',1e6
  elseif num >= 1e3
    return 'k',1e3
  elseif num >= 1e2
    return 'h',1e2
  elseif num >= 1e1
    return "da",1e1
  elseif num >= 1e-1
    return 'd',1e-1
  elseif num >= 1e-2
    return 'c',1e-2
  elseif num >= 1e-3
    return 'm',1e-3
  elseif num >= 1e-6
    return 'μ',1e-6
  elseif num >= 1e-9
    return 'n',1e-9
  elseif num >= 1e-12
    return 'p',1e-12
  elseif num >= 1e-15
    return 'f',1e-15
  elseif num >= 1e-18
    return 'a',1e-18
  elseif num >= 1e-21
    return 'z',1e-21
  elseif num >= 1e-24
    return 'y',1e-24
  end
end

"""
    plot(network)

Plots s,z,y,t
"""
function plot(network::DataNetwork,param::Tuple=(1,1),f::Function=dB;kwargs...)
  # Scale frequency
  prefix = closestPrefix(network.frequency[end])
  prettyFrequency = @. network.frequency / prefix[2]

  # Create trace of parameter
  plotVec = map(f,network.s_params[param[1],param[2],:])
  trace = scatter(;x=prettyFrequency,y=plotVec,kwargs...)
  layout = Layout(xaxis_title = "Frequency ($(prefix[1])Hz)")
  plot(trace,layout)
end

function plot(network::DataNetwork,f::Function;kwargs...)
  # Scale frequency
  prefix = closestPrefix(network.frequency[end])
  prettyFrequency = @. network.frequency / prefix[2]

  trace = scatter(;x=prettyFrequency,y=f(network),kwargs...)
  layout = Layout(xaxis_title = "Frequency ($(prefix[1])Hz)")
  plot(trace,layout)
end

function plot!(plot,network::DataNetwork,param::Tuple=(1,1),f::Function=dB;kwargs...)
  # Scale frequency
  prefix = closestPrefix(network.frequency[end])
  prettyFrequency = @. network.frequency / prefix[2]

  # Create trace of parameter
  plotVec = map(f,network.s_params[param[1],param[2],:])
  trace = scatter(;x=prettyFrequency,y=plotVec,kwargs...)

  # Append trace to plot
  addtraces!(plot,1,trace)
end

function plot!(plot,network::DataNetwork,f::Function;kwargs...)
  # Scale frequency
  prefix = closestPrefix(network.frequency[end])
  prettyFrequency = @. network.frequency / prefix[2]

  trace = scatter(;x=prettyFrequency,y=f(network),kwargs...)
  layout = Layout(xaxis_title = "Frequency ($(prefix[1])Hz)")

  # Append trace to plot
  addtraces!(plot,1,trace)
end

#  =============== Antenna Plotting Code =============== #

function createCartesianGriddedPattern(pattern::RadiationPattern,gainMin,gainMax)
    dataSize = (length(pattern.ϕ),length(pattern.θ))
    # Preallocalte matricies
    x = zeros(Float64,dataSize)
    y = zeros(Float64,dataSize)
    z = zeros(Float64,dataSize)

    # Reshape radius data
    r = [(data + abs(gainMin))/(gainMax+abs(gainMin)) for data in pattern.pattern]
    # Eliminate negative numbers
    for i in 1:dataSize[1], j in 1:dataSize[2]
        if r[i,j] < 0
            r[i,j] = 0
        end
    end

    for (i,phi) in enumerate(pattern.ϕ), (j,theta) in enumerate(pattern.θ)
        x[i,j] = r[i,j] * sind(theta) * cosd(phi)
        y[i,j] = r[i,j] * sind(theta) * sind(phi)
        z[i,j] = r[i,j] * cosd(theta)
    end
    return x,y,z
end

"""
        plotPattern3D(pattern,ϕ)
Plots the 3D Radiation Pattern of `pattern`. Optionally can set the
minimum and maximum gain with kwargs `gainMin` and `gainMax`.
"""
function plotPattern3D(pattern::RadiationPattern;gainMin=nothing,gainMax=nothing)
    # Scale data to max and min
    if gainMin == nothing
        gainMin = pattern.min[1]
    end
    if gainMax == nothing
        gainMax = pattern.max[1]
    end
    # Generate cartesian data
    x,y,z = createCartesianGriddedPattern(pattern,gainMin,gainMax)
    # Generate hover data
    text = ["$(round(pattern.pattern[i,j],digits=2) ) dBi<br>θ = $(pattern.θ[j])<br>ϕ = $(pattern.ϕ[i])"
            for i in 1:length(pattern.ϕ), j in 1:length(pattern.θ)]
    # Generate color data
    color = [x < gainMin ? gainMin : x for x in pattern.pattern]
    zeroaxis = attr(showgrid=false,showline=false,showticklabels=false,ticks="",title="",zeroline=false)
    l = Layout(paper_bgcolor="rgba(255,255,255, 0.9)",scene=attr(
               showticklabels=false,
               xaxis=zeroaxis,
               yaxis=zeroaxis,
               zaxis=zeroaxis),
               margin=attr(l=0, r=0, t=0, b=0),
               width=800, height=800)
    t = surface(x=x,y=y,z=z,surfacecolor=color,
                text=text,hoverinfo="text",colorbar="title"=>"dBi",
                colorscale="Viridis")
    plot(t,l)
end

"""
        plotPattern2D(pattern,ϕ)
Plots the 2D Radiation Pattern of `pattern` at the phi cut `ϕ`. Optionally can set the
minimum and maximum gain with kwargs `gainMin` and `gainMax`.
"""
function plotPattern2D(pattern::RadiationPattern,ϕ::Real;gainMin=nothing,gainMax=nothing)
    if gainMin == nothing
        gainMin = pattern.min[1]
    end
    if gainMax == nothing
        gainMax = pattern.max[1]
    end
    # Find which column is closest to the requested phi
    index = findmin(abs.(Array(pattern.ϕ).-ϕ))[2]
    t = scatterpolar(r=pattern.pattern[index,:],theta=pattern.θ)
    l = Layout(polar=attr(radialaxis=attr(angle=90,autorange=false,range=[gainMin,gainMax]),
                                                angularaxis=attr(rotation = 90,direction = "clockwise")))

    plot(t,l)
end

function update3DPlot!(plot,pattern::RadiationPattern,gainMin=nothing,gainMax=nothing)
    # Scale data to max and min
    if gainMin == nothing
        gainMin = pattern.min[1]
    end
    if gainMax == nothing
        gainMax = pattern.max[1]
    end
    # Color Data
    color = [x < gainMin ? gainMin : x for x in pattern.pattern]
    # Generate hover data
    text = ["$(round(pattern.pattern[i,j],digits=2) ) dBi<br>θ = $(pattern.θ[j])<br>ϕ = $(pattern.ϕ[i])"
            for i in 1:length(pattern.ϕ), j in 1:length(pattern.θ)]
    # Generate cartesian data
    x,y,z = createCartesianGriddedPattern(pattern,gainMin,gainMax)
    t = surface(x=x,y=y,z=z,surfacecolor=color,
                text=text,hoverinfo="text",colorbar="title"=>"dBi",
                colorscale="Viridis")
    # Update existing plot
    deletetraces!(plot,1)
    addtraces!(plot,1,t)
end
