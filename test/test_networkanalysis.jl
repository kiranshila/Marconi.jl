@testset "Converting between network parameters" begin
    # To and from z-s
    z11 = -14567.2412789287 - 148373.315116592im
    z12 = -14588.1106171651 - 148388.583516562im
    z21 = -14528.0522132692 - 148350.705757767im
    z22 = -14548.5996561832 - 148363.457002006im
    z_params = [z11 z12; z21 z22]
    s = z2s(z_params)
    @test z_params ≈ s2z(s) # Due to float error

    # to and from t-s
    s11 = 0.61*exp(im*165/180*pi)
    s21 = 3.72*exp(im*59/180*pi)
    s12 = 0.05*exp(im*42/180*pi)
    s22 = 0.45*exp(im*(-48/180)*pi)
    s_params = [s11 s12; s21 s22];
    @test t2s(s2t(s_params)) ≈ s_params
end
