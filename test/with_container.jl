@testset "with_container()" begin
    configs = [
        DockerConfig(; base_image = "julia:latest", verbose = true),
        DockerConfig(; base_image = "julia:latest", verbose = false),
        DockerConfig(;
            base_image = "julia:latest",
            verbose = true,
            docker_build_stdout = Base.devnull,
            docker_build_stderr = Base.devnull,
        ),
    ]
    for config in configs
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
