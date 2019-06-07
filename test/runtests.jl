using Marconi, Test

function tests()
  @testset "Subset of tests" begin
    @test pi_approximation() ≈ pi atol=1e-2
  end
end

tests()
