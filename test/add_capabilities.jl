@testset "add capabilities" begin
    config = DockerConfig(;
        base_image = "julia:latest",
        allow_advanced_features = true,
        add_capabilities = ["CAP_CHOWN"],
    )
    with_container() do container
        code = """
        println("This was a success.")
        """
        @test success(container, config, `julia -e $(code)`)
    end
end
