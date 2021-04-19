@testset "read-write maps" begin
    mktempdir() do tmpdir_ro
        mktempdir() do tmpdir_rw
            open(joinpath(tmpdir_ro, "myroinputfile"), "w") do io
                println(io, "Hello RO world!")
            end
            open(joinpath(tmpdir_rw, "myrwinputfile"), "w") do io
                println(io, "Hello RW world!")
            end
            x1 = read(joinpath(tmpdir_ro, "myroinputfile"), String)
            x2 = read(joinpath(tmpdir_rw, "myrwinputfile"), String)
            @test x1 == "Hello RO world!\n"
            @test x2 == "Hello RW world!\n"
            @test !ispath(joinpath(tmpdir_rw, "myrwoutputfile"))
            @test !isfile(joinpath(tmpdir_rw, "myrwoutputfile"))

            config = DockerConfig(;
                image = "julia:latest",
                read_only_maps = Dict(
                    "/home/myuser/workdir_ro" => tmpdir_ro,
                ),
                read_write_maps = Dict(
                    "/home/myuser/workdir_rw" => tmpdir_rw,
                ),
            )

            Docker.make_world_readable_recursively(tmpdir_ro)
            Docker.make_world_writeable_recursively(tmpdir_rw)

            with_container() do container
                code = """
                y1 = read("/home/myuser/workdir_ro/myroinputfile", String)
                y2 = read("/home/myuser/workdir_rw/myrwinputfile", String)
                if y1 != "Hello RO world!\n"
                    throw(ErrorException("File contents did not match"))
                end
                if y2 != "Hello RW world!\n"
                    throw(ErrorException("File contents did not match"))
                end
                if ispath("/home/myuser/workdir_rw/myrwoutputfile")
                    throw(ErrorException("The file exists, but it should not exist"))
                end
                if isfile("/home/myuser/workdir_rw/myrwoutputfile")
                    throw(ErrorException("The file exists, but it should not exist"))
                end
                open("/home/myuser/workdir_rw/myrwoutputfile", "w") do io
                    println(io, "I created and wrote this file inside the container.")
                end
                chmod("/home/myuser/workdir_rw/myrwoutputfile", 0o666)
                mktempdir() do tmpdir
                    open(joinpath(tmpdir, "sometemporaryfile"), "w") do io
                        println(io, "I wrote this file into a temporary directory.")
                    end
                end
                """
                @test success(container, config, `julia -e $(code)`)
            end

            @test ispath(joinpath(tmpdir_rw, "myrwoutputfile"))
            @test isfile(joinpath(tmpdir_rw, "myrwoutputfile"))
            z1 = read(joinpath(tmpdir_rw, "myrwoutputfile"), String)
            @test z1 == "I created and wrote this file inside the container.\n"
        end
    end
end
