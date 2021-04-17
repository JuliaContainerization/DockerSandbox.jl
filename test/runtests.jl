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
            cmd = `julia -e $(code)`
            @test success(container, config, cmd)
        end

        with_container() do container
            code = """
            throw(ErrorException("This was a failure."))
            """
            cmd = `julia -e $(code)`
            @test !success(container, config, cmd)
        end

        with_container() do container
            code = """
            println("This was a success.")
            """
            cmd = `julia -e $(code)`
            p = run(container, config, cmd; wait = false)
            wait(p)
            @test success(p)
        end

        with_container() do container
            code = """
            throw(ErrorException("This was a failure."))
            """
            cmd = `julia -e $(code)`
            p = run(container, config, cmd; wait = false)
            wait(p)
            @test !success(p)
        end
    end
end
