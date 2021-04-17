using Docker
using Test

@testset "Docker.jl" begin
    @testset "Test that Docker is installed" begin
        @test success(`docker --version`)
    end

    @testset "Basic test" begin
        config = DockerConfig(;
            image = "julia:latest",
            verbose = true,
        )

        with_container() do container
            code = """
            println("This was a success.")
            """
            @test success(container, config, `julia -e $(code)`)
        end

        with_container() do container
            code = """
            throw(ErrorException("This was a failure."))
            """
            @test !success(container, config, `julia -e $(code)`)
        end

        with_container() do container
            code = """
            println("This was a success.")
            """
            p = run(container, config, `julia -e $(code)`; wait = false)
            wait(p)
            @test success(p)
        end

        with_container() do container
            code = """
            throw(ErrorException("This was a failure."))
            """
            p = run(container, config, `julia -e $(code)`; wait = false)
            wait(p)
            @test !success(p)
        end
    end
end
