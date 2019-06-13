@testset "Converting between network parameters" begin
    # To and from z
    z11 = -14567.2412789287 - 148373.315116592im
    z12 = -14588.1106171651 - 148388.583516562im
    z21 = -14528.0522132692 - 148350.705757767im
    z22 = -14548.5996561832 - 148363.457002006im
    z_params = [z11 z12; z21 z22]
    s = z2s(z_params)
    @test z_params ≈ s2z(s) # Due to float error
end
