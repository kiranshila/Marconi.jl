@testset "Testing plotting capabilities" begin
    # Create an empty chart
    sc = SmithChart()
    # Change an attribute
    sc["title"] = "Test Chart"
    # Check it worked
    @test sc["title"] == "Test Chart"
    # Check adding data to plot
    bpf = readTouchstone("../examples/BPF.s2p")
    sc2 = plotSmith(bpf,(1,1))
    @test sizeof(sc2.contents) == 1
end
