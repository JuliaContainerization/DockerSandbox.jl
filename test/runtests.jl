using Docker
using Test

import Pkg
import TOML

@testset "Ensure that there are no non-stdlib dependencies" begin
    package_directories = String[
        dirname(dirname(pathof(Docker))),
        dirname(@__DIR__),
        dirname(dirname(@__FILE__)),
    ]
    for package_directory in package_directories
        package_project_filename = joinpath(package_directory, "Project.toml")
        predictmd_project = TOML.parsefile(package_project_filename)
        predictmd_direct_deps = predictmd_project["deps"]
        for (name, uuid) in pairs(predictmd_direct_deps)
            is_stdlib = Pkg.Types.is_stdlib(Base.UUID(uuid))
            if !is_stdlib
                @error("There is a non-stdlib dependency", name, uuid)
            end
            @test is_stdlib
        end
    end
end

@testset "Test that Docker is installed" begin
    @test success(`docker --version`)
end

@testset "Errors" begin
    @test_throws ArgumentError Docker._generate_dockerfile(DockerConfig(; image = "foo", platform = :foo))
end

@testset "with_container()" begin
    configs = [
        DockerConfig(; image = "julia:latest", verbose = true),
        DockerConfig(; image = "julia:latest", verbose = false),
        DockerConfig(;
            image = "julia:latest",
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
