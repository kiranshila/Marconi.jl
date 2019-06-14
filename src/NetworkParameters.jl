using LinearAlgebra

# Export Network Parameters
export y2s
export z2s
export s2z

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

function h2s(h::Array{A,2};Z0::B=50.) where {A <: Number, B <: Number}
end

function g2s(g::Array{A,2};Z0::B=50.) where {A <: Number, B <: Number}
end
