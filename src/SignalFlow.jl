using LightGraphs, MetaGraphs, GraphPlot

export graphFromS
export plotSGraph

function graphFromS(s::Array{T,2}) where {T <: Number}
    ports = size(s)[1]

    # Generate graph
    g = MetaDiGraph(ports*2)
    set_indexing_prop!(g, :name)

    # Add a and b wave nodes
    for i = 1:2:ports*2-1
        set_prop!(g,i,:name, "a$(i ÷ 2 + 1)")
        set_prop!(g,i+1,:name, "b$(i ÷ 2 + 1)")
    end

    # Add edges
    for i in 1:ports, j in 1:ports
        add_edge!(g,g["a$j",:name],g["b$i",:name])
        set_prop!(g,g["a$j",:name],g["b$i",:name],:weight, s[i,j])
    end

    return g
end

function plotSGraph(g::MetaDiGraph)
    gplot(g,
      nodelabel=[get_prop(g,v,:name) for v in 1:nv(g)],
      edgelabel=[complex2angleString(get_prop(g,e,:weight)) for e in edges(g)])
end
