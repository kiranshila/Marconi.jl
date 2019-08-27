# Starting points
ϵ_inf = 1.
ω_p = 2*pi*1e9
ν_c = 1.e6
μ_inf = 1.
μ_s = 1.
ω_0 = 2*pi*1e9
δ = 1.e9

x0 = [ϵ_inf,ω_p,ν_c,μ_inf,μ_s,ω_0,δ]

zim

ϵ,μ = optim_meta(zim,5.5e-3)

x0 = [ϵ_inf,ω_p,ν_c,μ_inf,μ_s,ω_0,δ]
lower = [0., 0.,0.,0.,0.,0.,0.]
upper = [Inf, Inf,Inf,Inf,Inf,Inf,Inf]
inner_optimizer = NelderMead()
res = optimize(x -> optim_meta_cost(x,zim,d=d),lower,upper, x0, Fminbox(inner_optimizer))

ld = LorentzDrude(x0...)

ld(2*pi*5e9)




zim = readTouchstone("Vivaldi_ZIM_UnitCell.s2p")
d = 5.5e-3

# Setup Model
model = Model(with_optimizer(Ipopt.Optimizer))

# Define Variables
@variable(model, ϵ_inf >= eps(), start = 1.)
@variable(model, ω_p >= eps(), start = 1.e9)
@variable(model, ν_c >= eps(), start = 1.e6)
@variable(model, μ_inf >= eps(), start = 1.)
@variable(model, μ_s >= eps(), start = 1.)
@variable(model, ω_0 >= eps(), start = 1.e9)
@variable(model, δ >= eps(), start = 1.e9)

# Fixed inputs
@variable(model, d == d)

# Register Cost Function
register(model, :optim_meta_cost, 7, optim_meta_cost, autodiff=true)

@NLobjective(model, Min, optim_meta_cost(ϵ_inf,ω_p,ν_c,μ_inf,μ_s,ω_0,δ,zim,d))

optimize!(model)
