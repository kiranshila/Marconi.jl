using PlotlyJS
using UUIDs
using Random

export plotPattern2D
export plotPattern3D
export +
export readHFSSPattern
export RadiationPattern
export ArrayFactor
export generateRectangularAF
export generateCircularAF
export applyAF
export phaseLocations
export html_plot

"""
    RadiationPattern
Stores a 3D antenna radiation pattern in spherical coordinates.
Φ and Θ are in degrees, pattern is in dBi
"""
mutable struct RadiationPattern
    ϕ::Union{AbstractRange,Array}
    θ::Union{AbstractRange,Array}
    pattern::Array{Real,2}
    min::Tuple
    max::Tuple
end

# Defualt Constructor
RadiationPattern(ϕ,θ,pattern) = RadiationPattern(ϕ,θ,pattern,(findmin(pattern)),(findmax(pattern)))

"""
    ArrayFactor
Stores the array factor due to N isotropic radiators located at `locations` with
phasor excitations `excitations`. Calling an `ArrayFactor` object with the arguments
ϕ,θ,and frequency will return in dB the value of the AF at that location in spherical
coordinates.
"""
mutable struct ArrayFactor
  locations::Array{Tuple{Real,Real,Real}}
  excitations::Array{Complex}
end

function Base.show(io::IO,AF::ArrayFactor)
    println(io,"An Array Factor with $(length(AF.excitations)) elements")
end

function (af::ArrayFactor)(ϕ,θ,freq)
    # Construct wave vector
    λ = c₀/freq
    k = (2*π)/(λ) .* [sind(θ)*cosd(ϕ),sind(θ)*sind(ϕ),cosd(θ)]
    # Constuct steering vector
    v = [exp(-1im*k⋅r) for r in af.locations]
    # Create array factor normalized to the total power of the excitations in the array
    return 10*log10(abs(transpose(af.excitations)*v)^2/sum(map(abs,af.excitations)))
end

"""
        RadiationPattern(AF,ϕ,θ,freq)
Constructs a `RadiationPattern` from an `ArrayFactor` sampled in `ϕ` and `θ` at `freq`
"""
function RadiationPattern(AF::ArrayFactor,ϕ::Union{AbstractRange,Array},θ::Union{AbstractRange,Array},freq::Real)
    RadiationPattern(ϕ,θ,[AF(phi,theta,freq) for phi in ϕ, theta in θ])
end

"""
        +(Pattern1,Pattern2)
Adds two patterns of equal size together. Useful for arrays
"""
function +(pattern_1::RadiationPattern,pattern_2::RadiationPattern)
    @assert pattern_1.ϕ == pattern_2.ϕ "Phi space must be identical"
    @assert pattern_1.θ == pattern_2.θ "Theta space must be identical"
    return RadiationPattern(pattern_1.ϕ,pattern_1.θ,pattern_1.pattern + pattern_2.pattern)
end

"""
        applyAF(pattern,AF,freq)
Applys an `ArrayFactor` to a `RadiationPattern`.
"""
function applyAF(pattern,AF,freq)
    return RadiationPattern(AF,pattern.ϕ,pattern.θ,freq) + pattern
end

"""
        generateRectangularAF(Nx,Ny,Spacingx,Spacingy,ϕ,θ,freq)
Creates an `ArrayFactor` object from a rectangular array that is `Nx` X `Ny`
big with spacing `Spacingx` and `Spacingy`. The excitations are phased such that
the main beam is in the `ϕ`, `θ`, direction at frequency `freq`.
"""
function generateRectangularAF(Nx,Ny,Spacingx,Spacingy,ϕ,θ,freq)
    # Create Locations
    Locations = []
    # 1D
    @assert Nx > 0 "Needs at least one component in x"
    @assert Nx > 0 "Needs at least one component in x"
    # 2D
    for i in 1:Nx, j in 1:Ny
        push!(Locations,((i-1)*Spacingx,(j-1)*Spacingy,0))
    end
    Phases = phaseLocations(Locations,ϕ,θ,freq)
    ArrayFactor(Locations,Phases)
end

"""
        phaseLocations(Locations,ϕ,θ,freq)
Given antennas at locations `Locations` which is a vector of 3-Tuples of cartesian coordinates,
calculate the corresponding phases to steer the beam in `ϕ` and `θ` at frequency `freq`
"""
function phaseLocations(Locations,ϕ,θ,freq)
    k = ((2*π*freq)/c₀) .* [sind(θ)*cosd(ϕ),sind(θ)*sind(ϕ),cosd(θ)]
    Phases = zeros(ComplexF64,length(Locations))
    for (i,position) in enumerate(Locations)
        Phases[i] = exp(1im*k⋅[position...])
    end
    return Phases
end

"""
        generateCircularAF(N,R,ϕ,θ,freq)
Creates an `ArrayFactor` object from a circular array with `N` excitations in a
circle with radius `R`. The excitations are phased such that
the main beam is in the `ϕ`, `θ`, direction at frequency `freq`.
"""
function generateCircularAF(N,R,ϕ,θ,freq)
    # Create Locations
    Locations = []
    for (i,ψ) in enumerate(range(0,2π,length=N))
        push!(Locations,(R*cos(ψ),R*sin(ψ),0))
    end
    Phases = phaseLocations(Locations,ϕ,θ,freq)
    ArrayFactor(Locations,Phases)
end

"""
        readHFSSPattern("myAntenna.csv")
Reads the exported fields from HFSS into a Marconi `RadiationPattern` object.
"""
function readHFSSPattern(filename::String)
    # Read Pattern
    patternData = CSV.read(filename) |> Matrix

    # Determine sampled space
    ϕ_min = Inf
    ϕ_max = -Inf
    θ_min = Inf
    θ_max = -Inf

    max_val = -Inf
    max_phi = 0
    max_theta = 0
    min_val = Inf
    min_phi = 0
    min_theta = 0

    for i in 1:size(patternData)[1], j in 1:size(patternData)[2]-1
        # Check column 1 for phi, 2 for theta
        if j == 1
            if patternData[i,j] > ϕ_max
                ϕ_max = patternData[i,j]
            elseif patternData[i,j] < ϕ_min
                ϕ_min = patternData[i,j]
            end
        elseif j == 2
            if patternData[i,j] > θ_max
                θ_max = patternData[i,j]
            elseif patternData[i,j] < θ_min
                θ_min = patternData[i,j]
            end
        elseif j == 3
            # Third column is data, do checks for min and max
            if patternData[i,j] > max_val
                max_val = patternData[i,j]
                max_phi = patternData[i,1]
                max_theta = patternData[i,2]
            end
            if patternData[i,j] < min_val
                min_val = patternData[i,j]
                min_phi = patternData[i,1]
                min_theta = patternData[i,2]
            end
        end
    end

    # Determine step size
    ϕ_step = patternData[2,1] - patternData[1,1]
    ϕ = ϕ_min:ϕ_step:ϕ_max
    θ_step = patternData[length(ϕ)+1,2] - patternData[1,2]
    θ = θ_min:θ_step:θ_max

    # Find the indicies for the min and max
    max_loc = CartesianIndex(findinrange(ϕ,max_phi),findinrange(θ,max_theta))
    min_loc = CartesianIndex(findinrange(ϕ,min_phi),findinrange(θ,min_theta))

    # Create pattern
    RadiationPattern(ϕ,θ,reshape(patternData[:,3],(length(ϕ),length(θ))),(min_val,min_loc),(max_val,max_loc))
end

function findmax(pattern::RadiationPattern)
    i = pattern.max[2][1]; j = pattern.max[2][2]
    return pattern.max[1],Array(pattern.ϕ)[i],Array(pattern.θ)[j]
end

function findmin(pattern::RadiationPattern)
    i = pattern.min[2][1]; j = pattern.min[2][2]
    return pattern.min[1],Array(pattern.ϕ)[i],Array(pattern.θ)[j]
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
               margin=attr(l=0, r=0, t=0, b=0))
    t = surface(x=x,y=y,z=z,surfacecolor=color,
                text=text,hoverinfo="text",colorbar="title"=>"dBi",
                colorscale="Viridis")
    plot(t,l)
end

function Base.show(io::IO,pattern::RadiationPattern)
  ϕ = Array(pattern.ϕ); θ = Array(pattern.θ)
  println(io,"$(length(pattern.pattern))-Element Radiation Pattern")
  println(io," Φ: $(ϕ[1]) - $(ϕ[end]) deg in $(ϕ[2]-ϕ[1]) deg steps")
  println(io," θ: $(θ[1]) - $(θ[end]) deg in $(θ[2]-θ[1]) deg steps")
end

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
