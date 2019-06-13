@testset "Testing marconi core functionality" begin
    # Reading touchstone
    bpf = readTouchstone("../examples/BPF.s2p")
    # Check attributes
    @test bpf.ports == 2
    @test bpf.Z0 == 50
end
