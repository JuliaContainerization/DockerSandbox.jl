@testset "environment variables" begin
    config = DockerConfig(;
        image = "julia:latest",
        env = Dict{String, String}("MY_ENVIRONMENT_VARIABLE" => "hello_world")
    )

    with_container() do container
        code = """
        println("This was a success.")
        if !haskey(ENV, "MY_ENVIRONMENT_VARIABLE")
            throw(ErrorException("environment variable does not exist"))
        end
        if ENV["MY_ENVIRONMENT_VARIABLE"] != "hello_world"
            throw(ErrorException("environment variable has the wrong value"))
        end
        """
        @test success(container, config, `julia -e $(code)`)
    end
end
