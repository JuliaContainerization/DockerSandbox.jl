"""
    DockerConfig(; kwargs...)

## Required Keyword Arguments:
- `image::String`

## Optional Keyword Arguments:
- `verbose::Bool = false`
- `env::Dict{String, String} = Dict{String, String}()`
- `platform::Symbol = :linux`
- `read_only_maps::Union{Dict{String, String}, Nothing} = nothing`
- `read_write_maps::Union{Dict{String, String}, Nothing} = nothing`
- `stdin::IO = Base.devnull`
- `stdout::IO = Base.stdout`
- `stderr::IO = Base.stderr`
- `docker_build_stdout::Union{IO, Nothing} = nothing`
- `docker_build_stderr::Union{IO, Nothing} = nothing`

"""
Base.@kwdef struct DockerConfig
    image::String
    verbose::Bool = false
    env::Dict{String, String} = Dict{String, String}()
    platform::Symbol = :linux
    read_only_maps::Union{Dict{String, String}, Nothing} = nothing
    read_write_maps::Union{Dict{String, String}, Nothing} = nothing
    stdin::IO = Base.devnull
    stdout::IO = Base.stdout
    stderr::IO = Base.stderr
    docker_build_stdout::Union{IO, Nothing} = nothing
    docker_build_stderr::Union{IO, Nothing} = nothing
end

"""
    DockerContainer()
"""
Base.@kwdef struct DockerContainer
    label::String = Random.randstring(10)
end
