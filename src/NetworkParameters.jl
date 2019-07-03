using LinearAlgebra

# Export Network Parameters
export s2z
export s2y
export s2t

export z2s
export z2y
export z2t

export y2s
export y2z
export y2t

export t2s

export cascade

#  =============== From S-Parameters =============== #
"""
        s2z(s)

Converts S-Parameters `s` to Z-Parameters. Optionally include reference
impedance with kwarg `Z0` with `s2z(s,Z0=50)`.
"""
function s2z(s::Array{A,2};Z0::B=50.) where {A <: Number, B <: Number}
    sqrtZref = Diagonal([√(Z0) for i in 1:size(s)[1]])
    return sqrtZref*(I+s)*(I-s)^-1*sqrtZref
end

"""
        s2y(s)

Converts S-Parameters `s` to Y-Parameters. Optionally include reference
impedance with kwarg `Z0` with `s2z(s,Z0=50)`.
"""
function s2y(s::Array{A,2};Z0::B=50.) where {A <: Number, B <: Number}
    sqrtYref = Diagonal([√(1/Z0) for i in 1:size(s)[1]])
    return sqrtYref*(I-s)*(I+s)^-1*sqrtYref
end

"""
        s2t(s)

Converts S-Parameters `s` to T-Parameters.
"""
function s2t(s::Array{T,2}) where {T <: Number}
    @assert size(s)[1] == 2 "s2t is only supported for 2 ports"
    return (1/s[2,1]) .* [s[1,2]*s[2,1] - s[1,1]*s[2,2] s[1,1];-s[2,2] 1]
end

#  =============== From Z-Parameters =============== #
"""
        z2s(z)

Converts Z-Parameters `z` to S-Parameters. Optionally include reference
impedance with kwarg `Z0` with `z2s(z,Z0=50)`.
"""
function z2s(z::Array{A,2};Z0::B=50.) where {A <: Number, B <: Number}
    sqrtYref = Diagonal([√(1/Z0) for i in 1:size(z)[1]])
    return (sqrtYref * z * sqrtYref - I)*(sqrtYref*z*sqrtYref + I)^-1
end

"""
        z2y(z)

Converts Z-Parameters `z` to Y-Parameters.
"""
function z2y(z::Array{A,2}) where {A <: Number}
    return z^-1
end

"""
        z2t(z)

Converts Z-Parameters `z` to T-Parameters. Optionally include reference
impedance with kwarg `Z0` with `z2s(z,Z0=50)`.
"""
function z2t(z::Array{A,2};Z0::B=50.) where {A <: Number, B <: Number}
    return s2t(z2s(z,Z0=Z0))
end

#  =============== From Y-Parameters =============== #
"""
        y2s(y)

Converts Y-Parameters `y` to S-Parameters. Optionally include reference
impedance with kwarg `Z0` with `y2s(y,Z0=50)`.
"""
function y2s(y::Array{A,2};Z0::B=50.) where {A <: Number, B <: Number}
    sqrtZref = Diagonal([√(Z0) for i in 1:size(y)[1]])
    return (I-sqrtZref*y*sqrtZref)*(I+sqrtZref*y*sqrtZref)^-1
end

"""
        y2z(y)

Converts Y-Parameters `y` to Z-Parameters.
"""
function y2z(y::Array{A,2}) where {A <: Number}
    return y^-1
end

"""
        y2t(y)

Converts Y-Parameters `y` to T-Parameters. Optionally include reference
impedance with kwarg `Z0` with `y2s(y,Z0=50)`.
"""
function y2t(y::Array{A,2};Z0::B=50.) where {A <: Number, B <: Number}
    return s2t(y2s(y,Z0=Z0))
end

#  =============== From T-Parameters =============== #

"""
        t2s(t)

Converts T-Parameters `t` to S-Parameters.
"""
function t2s(t::Array{T,2}) where {T <: Number}
    @assert size(t)[1] == 2 "t2s is only supported for 2 ports"
    return [t[1,2]/t[2,2] t[1,1]-((t[1,2]*t[2,1])/t[2,2]);
            1/t[2,2] -t[2,1]/t[2,2]]
end

#  =============== Network Functions =============== #

"""
    interpolate(network,frequencies)

Returns a new network object that contains data from `network` reinterpolated
to fit `frequencies`.
"""
function interpolate(network::DataNetwork,freqs::Array{T,1}) where {T <: Real}
  # Use BSplines for evenly spaced data, grids for uneven
  # First test for spacing
  spacing = network.frequency[2]-network.frequency[1]
  isEven = true
  for i in 2:length(network.frequency)-1
    next_freq = network.frequency[i]+spacing
    if network.frequency[i+1] != next_freq
      isEven = false
      break
    end
  end
  # Collect each S_Parameter slice down the frequency axis
  interps = Matrix{Any}(undef, network.ports,network.ports)
  if isEven
    # Create spacing range
    thisRange = range(network.frequency[1],stop=network.frequency[end],step=spacing)
    for i in 1:network.ports, j in 1:network.ports
      interps[i,j] = CubicSplineInterpolation(thisRange,[param[i,j] for param in network.s_params])
    end
  else
    for i in 1:network.ports, j in 1:network.ports
      interps[i,j] = LinearInterpolation(network.frequency, [param[i,j] for param in network.s_params])
    end
  end
  # Return network object with interpolated values
  DataNetwork(network.ports,network.Z0,freqs,[map(x->x(f),interps) for f in freqs])
end

interpolate(network::DataNetwork,freqs::Union{UnitRange,StepRangeLen}) = interpolate(network,Array(freqs))

"""
    cascade(net1,net2,net3,...,netN)

Returns a new `DataNetwork` that is the cascaded result of net1,net2,net3,...netN where the `nets` are
2-Port `DataNetwork` objects. Optionally takes kwarg `numpoints` for how many points in the result.
"""
function cascade(networks::T...;numpoints = 401) where {T <: AbstractNetwork}
    @assert length(networks) >= 2 "Must have at least two networks to cascade."
    for network in networks
        @assert network.ports == 2 "Cascade is for 2-Port networks, use `wire` for n-port"
    end

    # Find frequency range of result
    f_low = max([network.frequency[1] for network in networks] ...)
    f_high = min([network.frequency[end] for network in networks] ...)
    f_range = range(f_low,stop=f_high,length=numpoints)

    # Reinterpolate all the newtorks to match
    networks = [interpolate(network,f_range) for network in networks]

    # Convert to T networks
    t_params = [[s2t(params) for params in network.s_params] for network in networks]

    # Cascade
    cascade_result = [*([t_params[j][i] for j in 1:length(networks)] ...) for i in 1:numpoints]

    # Create new network and return
    return DataNetwork(2,50,Array(f_range),[t2s(t) for t in cascade_result])
end
