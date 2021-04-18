"""
$(DocStringExtensions.TYPEDEF)

## Fields:
$(DocStringExtensions.TYPEDFIELDS )
"""
Base.@kwdef struct DockerConfig
    image::String
    env::Dict{String, String}             = Dict{String, String}()
    platform::Symbol                      = :linux
    read_only_maps::Dict{String, String}  = Dict{String, String}()
    read_write_maps::Dict{String, String} = Dict{String, String}()
    stderr::IO                            = Base.stderr
    stderr_docker_build::IO               = Base.stderr
    stdin::IO                             = Base.devnull
    stdin_docker_build::IO                = Base.devnull
    stdout::IO                            = Base.stdout
    stdout_docker_build::IO               = Base.stdout
    verbose::Bool                         = false
end

"""
$(DocStringExtensions.TYPEDEF)

## Fields:
$(DocStringExtensions.TYPEDFIELDS )
"""
Base.@kwdef struct DockerContainer
    label::String = Random.randstring(10)
end
