using LinearAlgebra

# Export Network Parameters
export y2s
export z2s
export s2z
export s2t
export t2s
export cascade

"""
        y2s(y)

Converts Y-Parameters `y` to S-Parameters. Optionally include reference
impedance with kwarg `Z0` with `y2s(y,Z0=50)`.
"""
function y2s(y::Array{A,2};Z0::B=50.) where {A <: Number, B <: Number}
    # We have to downcast to complex because of type weirdness in Diagonal
    Gref = Diagonal([1/√(abs(real(Z0))) for i in 1:size(y)[1]])
    Zref = Diagonal([Z0 for i in 1:size(y)[1]])

    return Gref * (convert(Array{Complex{Float64},2},I - Zref * y)) *
                  (convert(Array{Complex{Float64},2},I + Zref * y))^-1 *
                  complex(Gref)^-1
end

"""
        z2s(z)

Converts Z-Parameters `z` to S-Parameters. Optionally include reference
impedance with kwarg `Z0` with `z2s(z,Z0=50)`.
"""
function z2s(z::Array{A,2};Z0::B=50.) where {A <: Number, B <: Number}
    Gref = Diagonal([1/√(abs(real(Z0))) for i in 1:size(z)[1]])
    Zref = Diagonal([Z0 for i in 1:size(z)[1]])

    return Gref * (convert(Array{Complex{Float64},2},z - Zref)) *
                  (convert(Array{Complex{Float64},2},z + Zref))^-1 *
                  complex(Gref)^-1
end

"""
        s2z(s)

Converts S-Parameters `s` to Z-Parameters. Optionally include reference
impedance with kwarg `Z0` with `s2z(s,Z0=50)`.
"""
function s2z(s::Array{A,2};Z0::B=50.) where {A <: Number, B <: Number}
    sqrtZref = Diagonal([√(Z0) for i in 1:size(s)[1]])
    return sqrtZref*(I-s)^-1*(I+s)*sqrtZref
end

"""
        s2t(s)

Converts S-Parameters `s` to T-Parameters.
"""
function s2t(s::Array{T,2}) where {T <: Number}
    @assert size(s)[1] == 2 "s2t is only supported for 2 ports"
    return (1/s[2,1]) .* [s[1,2]*s[2,1] - s[1,1]*s[2,2] s[1,1];-s[2,2] 1]
end

"""
        t2s(t)

Converts T-Parameters `t` to S-Parameters.
"""
function t2s(t::Array{T,2}) where {T <: Number}
    @assert size(t)[1] == 2 "t2s is only supported for 2 ports"
    return [t[1,2]/t[2,2] t[1,1]-((t[1,2]*t[2,1])/t[2,2]);
            1/t[2,2] -t[2,1]/t[2,2]]
end

function cascade(networks::T...) where {T <: AbstractNetwork}
    @assert length(networks) >= 2 "Must have at least two networks to cascade."
    t_networks = [[s2t(params) for params in network.s_params] for network in networks]
    return t_networks
end
