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
end
