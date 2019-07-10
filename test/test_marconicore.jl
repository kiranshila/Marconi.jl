@testset "Testing marconi core functionality" begin
    # Reading touchstone
    bpf = readTouchstone("../examples/BPF.s2p")
    # Check attributes
    @test bpf.ports == 2
    @test bpf.Z0 == 50

    # Test creating equation-driven network
    function inductorAndResistor(;freq,Z0)
        z = 30 + im*2*pi*freq*1e-9
        return (z-Z0)/(z+Z0)
    end

    # Check we are testing bad equation inputs
    @test_throws AssertionError EquationNetwork(2,50,inductorAndResistor)

    # Check reading and writing touchstone 1 port
    short = readTouchstone("../examples/Short.s1p")
    writeTouchstone(short,"../examples/Short_Test.s1p")
    short_test = readTouchstone("../examples/Short_Test.s1p")
    rm("../examples/Short_Test.s1p")
    @test short_test == short

    # Check reading and writing touchstone 2 port
    amp = readTouchstone("../examples/Amp.s2p")
    writeTouchstone(amp,"../examples/Amp_Test.s2p")
    amp_test = readTouchstone("../examples/Amp_Test.s2p")
    rm("../examples/Amp_Test.s1p")
    @test amp_test == amp
end
