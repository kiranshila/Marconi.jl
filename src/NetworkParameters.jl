using LinearAlgebra

# Export Network Parameters
export y2s
export z2s
export s2z

"""
        y2s(y)

Converts Y-Parameters `y` to S-Parameters. Optionally include reference
impedance with kwarg `Z0` with `y2s(y,Z0=50)`.

# Example
```julia-repl
y11 =  0.0488133074245012 - 0.390764155450191im
y12 = -0.0488588365420561 + 0.390719345880018im
y21 = -0.0487261119282660 + 0.390851884427087im
y22 =  0.0487710062903760 - 0.390800401433241im

y_params = [y11 y12; y21 y22]

julia> y2s(y_params)
2×2 Array{Complex{Float64},2}:
 0.00381839+0.0247966im    0.996111-0.0249991im
   0.996392-0.0253812im  0.00374364+0.0249161im

```
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

# Example
```julia-repl
z11 = -14567.2412789287 - 148373.315116592im
z12 = -14588.1106171651 - 148388.583516562im
z21 = -14528.0522132692 - 148350.705757767im
z22 = -14548.5996561832 - 148363.457002006im

z_params = [z11 z12; z21 z22]

julia> z2s(z_params)
2×2 Array{Complex{Float64},2}:
 0.00381839+0.0247966im    0.996392-0.0253812im
   0.996111-0.0249991im  0.00374364+0.0249161im

```
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
