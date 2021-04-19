@testset "Errors" begin
    @testset begin
        config = DockerConfig(; base_image = "foo", platform = :foo)
        mktempdir() do build_directory
            @test_throws ArgumentError Docker._generate_dockerfile(config)
        end
    end

    @testset begin
        configs = [
            DockerConfig(;
                base_image = "julia:latest",
                read_only_maps = Dict("/" => "/foo"),
            ),
            DockerConfig(;
                base_image = "julia:latest",
                read_write_maps = Dict("/" => "/foo"),
            ),
        ]
        for config in configs
            with_container() do container
                code = """
                println("123")
                """
                @test_throws ArgumentError run(container, config, `julia -e $(code)`)
            end
        end
    end
end
