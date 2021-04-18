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
