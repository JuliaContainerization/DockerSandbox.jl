Base.@kwdef struct DockerConfig
    image::String
    env::Base.ImmutableDict{String, String}             = Base.ImmutableDict{String, String}()
    pwd::String                                         = "/"
    read_only_maps::Base.ImmutableDict{String, String}  = Base.ImmutableDict{String, String}()
    read_write_maps::Base.ImmutableDict{String, String} = Base.ImmutableDict{String, String}()
    stderr::IO                                          = Base.stderr
    stdin::IO                                           = Base.stdin
    stdout::IO                                          = Base.stdout
    verbose::Bool                                       = false
end

Base.@kwdef struct DockerContainer
    label::String = Random.randstring(10)
end
