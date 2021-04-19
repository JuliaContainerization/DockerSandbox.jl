@testset "read-only maps" begin
    mktempdir() do tmpdir_ro
        open(joinpath(tmpdir_ro, "myroinputfile"), "w") do io
            println(io, "Hello RO world!")
        end
        x1 = read(joinpath(tmpdir_ro, "myroinputfile"), String)
        @test x1 == "Hello RO world!\n"

        config = DockerConfig(;
            image = "julia:latest",
            read_only_maps = Dict(
                "/home/myuser/workdir_ro" => tmpdir_ro,
            ),
        )


        Utils.make_world_readable_recursively(tmpdir_ro)

        with_container() do container
            code = """
            y1 = read("/home/myuser/workdir_ro/myroinputfile", String)
            if y1 != "Hello RO world!\n"
                throw(ErrorException("File contents did not match"))
            end
            mktempdir() do tmpdir
                open(joinpath(tmpdir, "sometemporaryfile"), "w") do io
                    println(io, "I wrote this file into a temporary directory.")
                end
            end
            """
            @test success(container, config, `julia -e $(code)`)
        end
    end
end
