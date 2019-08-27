# Implementations of Homogenization and Parameter Retrieval from Dr. R. Rumpf
using LinearAlgebra
#using Optim
using JuMP
using Ipopt

export metamaterialParams
export LorentzDrude
export optim_meta_cost

"""
    metamaterialParams(net)

Wrapper for solving metamaterial parameters.

`method` can be set to
`:NRW` for the Nicholson-Ross-Weir Method,
`:Smith` for the D. R. Smith method,
`:Optim` for an optimization-based approach,

Returns ϵᵣ , μᵣ , and n
"""
function metamaterialParams(network::AbstractNetwork,d::Real;method = :NRW)
    if method == :NRW
        nrw_meta(network,d)
    end
end

function nrw_meta(network::AbstractNetwork,d::Real)
    # Setup
    numpoints = length(network.frequency)
    S = [@. conj(s) for s in network.s_params]
    k₀ = @. 2*pi*network.frequency/c₀
    # Calculate X
    X = [(1-s[2,1]^2+s[1,1]^2)/(2*s[1,1]) for s in S]
    # Calculate r with sign ambiguity resolution for passive materials
    # And calculate t
    r = zeros(ComplexF64,numpoints)
    t = zeros(ComplexF64,numpoints)
    for i = 1:numpoints
        # Solve r
        arg = √(X[i]^2 - 1.)
        if abs(X[i]+arg) <= 1.
            r[i] = X[i] + arg
        else
            r[i] = X[i] - arg
        end
        # Solve t
        t[i] = (S[i][1,1]+S[i][2,1]-r[i]) /
               (1-(S[i][1,1]+S[i][2,1])*r[i])
    end
    # Solve for impedance
    η = @. η₀*(1+r)/(1-r)
    # Solve for n
    n = zeros(ComplexF64,numpoints)
    for i = 1:numpoints
        n[i] = log(t[i]) / (1im*k₀[i]*d)
    end
    # Return ϵ, μ, and n
    return @. n * (η₀/η) ,n*(η/η₀), n
end

#FIXME
function smith_meta(network::AbstractNetwork,d::Real;tries=1000)
    # Setup
    numpoints = length(network.frequency)
    S = [@. conj(s) for s in network.s_params]
    k₀ = @. 2*pi*network.frequency/c₀
    # Solve for impedance
    η = [√(((1+s[1,1])^2 - s[2,1]^2)/((1-s[1,1])^2-s[2,1]^2)) for s in S]
    η = @. η*sign(real(η))
    # Reflection and Transmission
    r = @. (η-η₀)/(η-η₀)
    t = zeros(ComplexF64,numpoints)
    n_doubleprime = zeros(ComplexF64,numpoints)
    for i = 1:numpoints
        t[i] = S[i][2,1]/(1-S[i][1,1]*r[i])
        n_doubleprime[i] = -(1/(k₀[i]*d))*real(log(t[i]))
    end
    # Hard part - find m that satisfies branch condition
    m = 0
    n_prime = zeros(ComplexF64,numpoints)
    while m <= tries
        bad_m = false
        # Calculate n_prime for ALL frequencies
        for i = 1:numpoints
            n_prime[i] = -(1/(k₀[i]*d))*(imag(log(t[i]))+2*pi*m)
            # Check is condition is valid and move on to next m if not
            if abs(n_prime[i]*imag(η[i])) > abs(n_doubleprime[i]*real(η[i]))
                println("$m")
                bad_m = true
                break
            end
        end
        # Check if flag was thrown
        if bad_m
            m += 1
        else
            break
        end
    end
    # Build n vector
    n = [n_prime[i] + 1im*n_doubleprime[i] for i in 1:numpoints]
    # Return params
    return @. n * (η₀/η) ,n*(η/η₀), n, m
end

" Requires a large frequency sweep for validity of Kramers-Kronig relation"
function szabo_meta(network::AbstractNetwork,d::Real)
    # Setup
    numpoints = length(network.frequency)
    ω = @. 2*pi*network.frequency
    S = [@. conj(s) for s in network.s_params]
    k₀ = @. 2*pi*network.frequency/c₀
    Δω = ω[2] - ω[1]
    # Check for equispacing
    for i = 2:numpoints-1
        thisΔ = 2*pi*(network.frequency[i+1] - network.frequency[i])
        @assert thisΔ ≈ Δω "Frequency must be equally spaced"
    end
    # Solve for impedance
    η = [√(((1+s[1,1])^2 - s[2,1]^2)/((1-s[1,1])^2-s[2,1]^2)) for s in S]
    η = @. η*sign(real(η))
    exp_ink₀d = zeros(ComplexF64,numpoints)
    for i = 1:numpoints
        exp_ink₀d[i] = S[i][2,1]/(1-S[i][1,1]*((η[i]-1)/(η[i]+1)))
    end
    # Calculate Refractive Index
    n = @. imag(log(exp_ink₀d)) - 1im*real(log(exp_ink₀d))/k₀*d

    #  Kramers-Kronig
    n_re_KK = zeros(Real,numpoints)

    # First Point
    term_a = imag(n[2]) * ω[2]/ω[2]^2 - ω[1]^2
    for i = 2:numpoints-1
        term_b = imag(n[i+1])*ω[i+1]/ω[i+1]^2- ω[1]^2
        n_re_KK[1] = n_re_KK[1] + term_a + term_b
        term_a = term_b
    end
    n_re_KK[1] = 1 + Δω/pi*n_re_KK[1]

    # Last Point
    term_a = imag(n[1]) * ω[1]/ω[1]^2 - ω[numpoints]^2
    for i = 1:numpoints-2
        term_b = imag(n[i+1])*ω[i+1]/ω[i+1]^2- ω[numpoints]^2
        n_re_KK[numpoints] = n_re_KK[numpoints] + term_a + term_b
        term_a = term_b
    end
    n_re_KK[numpoints] = 1 + Δω/pi*n_re_KK[numpoints]

    # Middle Points
    for i = 2:numpoints-1
        term_a = imag(n[1])*ω[1]/(ω[1]^2 - ω[i]^2)
        for j = 1:i-2
            term_b = imag(n[j+1])*ω[j+1]/ω[j+1]^2 - ω[i]^2
            n_re_KK[i] = n_re_KK[i] + term_a + term_b
            term_a = term_b
        end
        term_a = imag(n[i+1])*ω[i+1]/(ω[i+1]^2-ω[i]^2)
        for j = i+1:numpoints-1
            term_b = imag(n[j+1])*ω[j+1]/ω[j+1]^2 - ω[i]^2
            n_re_KK[i] = n_re_KK[i] + term_a + term_b
            term_a = term_b
        end
        n_re_KK[i] = 1 + Δω/pi*n_re_KK[i]
    end

    # Find branch number
    m = @. round((n_re_KK - real(n)) * k₀ * d/(2*pi))

    # Find real part of n
    n = @. n + 2*pi*m/(k₀*d)

    # Return ϵ, μ, and n
    return @. conj(n/η), conj(n*η), n
end

function optim_meta(network::DataNetwork,d::Real)
    numpoints = length(network.frequency)

    # Starting points
    ϵ_inf = 1.
    ω_p = 2*pi*1e9
    ν_c = 1.e6
    μ_inf = 1.
    μ_s = 1.
    ω_0 = 2*pi*1e9
    δ = 1.e9

    # Optimize
    #==
    x0 = [ϵ_inf,ω_p,ν_c,μ_inf,μ_s,ω_0,δ]
    lower = fill(0.,7)
    upper = fill(Inf,7)
    inner_optimizer = SimulatedAnnealing()
    res = optimize(x -> optim_meta_cost(x,network,d=d),lower,upper, x0, Fminbox(inner_optimizer))
    if !Optim.converged(res)
        println("Optimizer did not converge")
    end
    # Return results
    ld = LorentzDrude(Optim.minimizer(res)...)
    ϵ = [ld(2*pi*f)[1] for f in network.frequency]
    μ = [ld(2*pi*f)[2] for f in network.frequency]

    return @. ϵ,μ,√(μ*ϵ),res
    ==#

    model = Model(with_optimizer(Ipopt.Optimizer))


end


function optim_meta_cost(ϵ_inf::Real,ω_p::Real,ν_c::Real,μ_inf::Real,μ_s::Real,ω_0::Real,δ::Real,target_network::DataNetwork,d::Real)
    # Generate S-Paramters
    ld = LorentzDrude(ϵ_inf,ω_p,ν_c,μ_inf,μ_s,ω_0,δ)
    s_params = model_meta(ld,freqs=target_network.frequency,d=d)
    # Generate Cost
    sum([abs(s_params[i][1,1] - target_network.s_params[i][1,1]) +
         abs(s_params[i][2,1] - target_network.s_params[i][2,1]) for i in 1:length(s_params)])
end

"""
        model_meta(index,impedance,2.4e9,5.5e-3,)

FIXME
Returns S-Parmaeters an ideal metamaterial slab as defined by Lorentz-Drude dispersive model.

X. Chen - "Robust methods to retrieve the constituitive effective parametres of metamaterials"
"""
function model_meta(ld::LorentzDrude;freqs::Union{StepRangeLen,Array},d::Real)
    # Setup
    ω = @. 2*pi*freqs
    numpoints = length(freqs)

    # Sample at all freqs
    ld_results = [ld(omega) for omega in ω]
    ϵ = [result[1] for result in ld_results]
    μ = [result[2] for result in ld_results]

    # Calculate impedance and index of refraction
    η = @. η₀*√(μ/ϵ)
    n = @. √(μ*ϵ)

    # Adjust for passive conditions
    η = @. η*sign(real(η))
    n = @. n*sign(imag(n))

    # Calculate reflection and transmission
    r = @. (η-η₀)/(η+η₀)
    t = @. exp(-1im*(ω/c₀)*n*d)

    # Calculate S-Parameters
    S11 = @. ((1-t^2)*r) / (1-r^2*t^2)
    S21 = @. ((1-r^2)*t) / (1-r^2*t^2)

    # Return S-Matrix
    [[S11[i] S21[i]; S21[i] S11[i]] for i in 1:numpoints]
end

mutable struct LorentzDrude
    ϵ_inf::Real
    ω_p::Real
    ν_c::Real
    μ_inf::Real
    μ_s::Real
    ω_0::Real
    δ::Real
end

(ld::LorentzDrude)(ω::Real) = ld.ϵ_inf - (ld.ω_p^2)/(ω*(ω-1im*ld.ν_c)),ld.μ_inf + ((ld.μ_s - ld.μ_inf)*ld.ω_0^2) / (ld.ω_0^2 + 1im*ω*ld.δ - ω^2)
