using PlotlyJS

export plotPattern2D
export plotPattern3D

function plotPattern2D(pattern::RadiationPattern,ϕ::Real;gainMin=nothing,gainMax=nothing)
    if gainMin == nothing
        gainMin = findmin(pattern)[1]
    end
    if gainMax == nothing
        gainMax = findmax(pattern)[1]
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

function plotPattern3D(pattern::RadiationPattern;gainMin=nothing,gainMax=nothing)
    # Scale data to max and min
    if gainMin == nothing
        @show gainMin = minimum(x->isnan(x) ? -Inf : x,pattern.pattern)
    end
    if gainMax == nothing
        @show gainMax = maximum(x->isnan(x) ? -Inf : x,pattern.pattern)
    end
    # Generate cartesian data
    x,y,z = createCartesianGriddedPattern(pattern,gainMin,gainMax)
    # Generate hover data
    text = ["$num dBi" for num in pattern.pattern]
    zeroaxis = attr(showgrid=false,showline=false,showticklabels=false,ticks="",title="",zeroline=false)
    l = Layout(paper_bgcolor="rgba(255,255,255, 0.9)",scene=attr(
               showticklabels=false,
               xaxis=zeroaxis,
               yaxis=zeroaxis,
               zaxis=zeroaxis))
    t = surface(x=x,y=y,z=z,surfacecolor=pattern.pattern,
                text=text,hoverinfo="text",colorbar="title"=>"dBi",
                colorscale="Viridis")
    plot(t,l)
end
