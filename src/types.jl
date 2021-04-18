"""
$(DocStringExtensions.TYPEDEF)

## Fields:
$(DocStringExtensions.TYPEDFIELDS )
"""
Base.@kwdef struct DockerConfig
    image::String
    verbose::Bool                         = false
    env::Dict{String, String}             = Dict{String, String}()
    platform::Symbol                      = :linux
    read_only_maps::Dict{String, String}  = Dict{String, String}()
    read_write_maps::Dict{String, String} = Dict{String, String}()
    stdin::IO                             = Base.devnull
    stdout::IO                            = Base.stdout
    stderr::IO                            = Base.stderr
    stdin_docker_build::IO                = Base.devnull
    stdout_docker_build::IO               = Base.stdout
    stderr_docker_build::IO               = Base.stderr
end

"""
$(DocStringExtensions.TYPEDEF)

## Fields:
$(DocStringExtensions.TYPEDFIELDS )
"""
Base.@kwdef struct DockerContainer
    label::String = Random.randstring(10)
end
