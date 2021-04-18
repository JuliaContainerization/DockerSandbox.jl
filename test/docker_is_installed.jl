@testset "Test that Docker is installed" begin
    @test success(`docker --version`)
end
