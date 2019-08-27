using Revise
using Marconi
using PGFPlotsX

function inductorAndResistor(L=1e-9,R=50;freq,Z0)
    z = R + im*2*pi*freq*L
    return (z-Z0)/(z+Z0)
end


short = readTouchstone("examples/Short.s1p")

writeTouchstone(short,"short.s1p")

ax = plotRectangular(bpf,(1,1))

plotRectangular!(ax,bpf,(2,1))

ax["width"] = "20 cm"

ax

freqs = 1e9:10e6:10e9

RL = EquationNetwork(1,50,inductorAndResistor)

plotRectangular(RL,(1,1),freqs=[100e6 200e6 300e6 400e6],args=(1e-9,35))

equationToDataNetwork(RL,args=(1e-9,50),freqs=Array(1e9:1e6:10e9))

ax = plotSmithData(RL,(1,1),freqs=1e9:10e6:10e9,args=(1e-9,30))

plotSmithData!(ax,RL,(1,1),freqs=1e9:10e6:10e9,args=(1e-9,90))

ax = plotRectangular(RL,(1,1),freqs=freqs,args=(1e-9,90))

plotRectangular!(ax,RL,(1,1),freqs=freqs,args=(1e-9,10))

ax = plotRectangular(RL,testK,args=(1e-9,30),freqs=Array(freqs))


function filterNet(f_center=1e9,rolloff=1;freq,Z0)
    gauss = f_center / (abs(freq-f_center)+f_center)*rolloff
    return [sqrt(1-gauss^2)  gauss;gauss sqrt(1-gauss^2)]
end

filterNet(1e9,1,freq=10e9,Z0=50)

filter = EquationNetwork(2,50,filterNet)

ax = plotRectangular(filter,(2,1),freqs=range(500e5,stop=1.5e9,length=201),args=(1e9,1))

plotRectangular!(ax,filter,(1,1),freqs=range(500e5,stop=1.5e9,length=201))

amp = readTouchstone("examples/Amp.s2p")

net = cascade(amp,filter)

plotRectangular!(ax,net,(1,1))

plotRectangular!(ax,amp,(2,1))

plotRectangular!(ax,filter,(2,1),freqs=Array(10e6:10e6:18e9))

function batchShow(nets::Vararg{AbstractNetwork,N} where N)
    for net in nets
        println(net)
    end
end



short = readTouchstone("examples/Short.s1p")
writeTouchstone(short,"examples/Short_Test.s1p")
short_test = readTouchstone("examples/Short_Test.s1p")
short_test == short

amp = readTouchstone("examples/Amp.s2p")
writeTouchstone(amp,"examples/Amp_Test.s2p")
amp_test = readTouchstone("examples/Amp_Test.s2p")
amp_test == amp


jfet = readTouchstone("examples/CE3520K3.s2p")
plotRectangular(jfet,testMUG,label="MUG")

zim = readTouchstone("Vivaldi_ZIM_UnitCell.s2p")





ϵ, μ, n = optim_meta(zim,5.5e-3)







ax = @pgf Axis({title = "Metamaterial Parameter Extraction",xlabel = "GHz"},PlotInc({no_marks},
                Coordinates(zim.frequency ./ 1e9,real(ϵ))),
                LegendEntry(raw"$Re[\epsilon]$"))

plt = @pgf PlotInc({no_marks},Coordinates(zim.frequency ./ 1e9,imag(ϵ)))
push!(ax,plt)
push!(ax,@pgf(LegendEntry(raw"$Imag[\epsilon]$")))

plt = @pgf PlotInc({no_marks},Coordinates(zim.frequency ./ 1e9,real(n)))
push!(ax,plt)
push!(ax,@pgf(LegendEntry(raw"$Re[n]$")))

ax

pgfsave("Plot.png",ax,dpi=500)






initial_guess = [1.,1,1,1]
target_s = zim.s_params[201]
freq = zim.frequency[201]
d = 5.5e-3

optim_meta_cost(initial_guess,target_s,d=d,freq=freq)

res = optimize(x -> optim_meta_cost(x,target_s,d=d,freq=freq),initial_guess)

optim_meta(zim,5.5e-3)


ϵ = n * (η₀/η)

η = η₀*n[300]/ϵ[300]


model_meta(n[300],η,zim.frequency[300],5.5e-3)

zim.s_params[300]
