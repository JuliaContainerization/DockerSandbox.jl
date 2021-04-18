"""
    docker_image_label(container::DockerContainer)
"""
function docker_image_label(container::DockerContainer)
    return string("org.julialang.docker.jl=", container.label)
end

function _assert_no_nonword_characters(str::String)
    isascii(str) || throw(ArgumentError("String is not an ASCII string"))
    occursin(r"^[A-Za-z0-9_]*?$", str) || throw(ArgumentError("String contains one or more nonword characters"))
    return nothing
end

function _replace_nonword_character(char::Char)
    if occursin(r"^\w$", string(char))
        return char
    else
        return '_'
    end
end

function _replace_all_nonword_characters(str::String)
    isascii(str) || throw(ArgumentError("String is not an ASCII string"))
    old_chars = collect(str)
    new_chars = _replace_nonword_character.(old_chars)
    new_str = join(new_chars)
    _assert_no_nonword_characters(new_str)
    return new_str
end

"""
    docker_image_name(image::String)
"""
function docker_image_name(image::String)
    docker_image = string(
        "julialang_dockerjl:",
        _replace_all_nonword_characters(image),
        "_",
        string(Base._crc32c(image), base=16),
    )
    return docker_image
end

function _generate_docker_copy_commands(; hostpath::String,
                                          containerpath::String)
    return """
    COPY --chown=myuser:myuser $(hostpath) $(containerpath)
    RUN chown --recursive myuser $(containerpath)
    RUN chgrp --recursive myuser $(containerpath)
    RUN chmod --recursive u=-x $(containerpath)
    RUN chmod --recursive u=rwX $(containerpath)
    RUN chmod --recursive g=-rwx,o=-rwx $(containerpath)
    """
end

function _generate_dockerfile(config::DockerConfig, build_directory::String)
    read_only_mappings = Dict{Int, Dict{Symbol, String}}()
    for (i, (dst, src)) in enumerate(pairs(config.read_only_maps))
       read_only_mappings[i] = Dict{Symbol, String}()
       read_only_mappings[i][:dst] = dst
       read_only_mappings[i][:src] = src
       read_only_mappings[i][:intermediate_dirname] = "RO_$(i)"
       read_only_mappings[i][:intermediate_abspath] = joinpath(build_directory, "RO_$(i)")
    end
    for i in keys(read_only_mappings)
        cp(
            read_only_mappings[i][:src],
            read_only_mappings[i][:intermediate_abspath];
            force = true,
        )
    end
    copy_commands = ""
    for i in keys(read_only_mappings)
        new_copy_commands = _generate_docker_copy_commands(;
            hostpath = read_only_mappings[i][:intermediate_dirname],
            containerpath = read_only_mappings[i][:dst],
        )
        copy_commands = string(
            strip(copy_commands),
            "\n",
            strip(new_copy_commands),
        )
    end
    copy_commands = strip(copy_commands)
    if config.platform === :linux
        dockerfile = """
        FROM --platform=linux $(config.image)
        RUN usermod --lock root
        RUN groupadd --system myuser
        RUN useradd --create-home --shell /bin/bash --system --gid myuser myuser
        $(copy_commands)
        USER myuser
        """
    else
        msg = "Invalid value for config.platform: $(config.platform)"
        throw(ArgumentError(msg))
    end
    if config.verbose
        docker_build_stderr = _get_docker_build_stderr(config)
        println(docker_build_stderr, "# BEGIN DOCKERFILE")
        println(docker_build_stderr, "\n")
        println(docker_build_stderr, dockerfile)
        println(docker_build_stderr, "\n")
        println(docker_build_stderr, "# END DOCKERFILE")
    end
    return dockerfile
end

function _get_docker_build_stdout(config::DockerConfig)
    if config.docker_build_stdout === nothing
        if config.verbose
            docker_build_stdout = Base.stdout
        else
            docker_build_stdout = Base.devnull
        end
    else
        docker_build_stdout = config.docker_build_stdout
    end
    (docker_build_stdout isa IO) || throw(ArgumentError("docker_build_stdout must be an IO"))
    return docker_build_stdout
end

function _get_docker_build_stderr(config::DockerConfig)
    if config.docker_build_stderr === nothing
        if config.verbose
            docker_build_stderr = Base.stderr
        else
            docker_build_stderr = Base.devnull
        end
    else
        docker_build_stderr = config.docker_build_stderr
    end
    (docker_build_stderr isa IO) || throw(ArgumentError("docker_build_stderr must be an IO"))
    return docker_build_stderr
end

"""
    build_docker_image(container::DockerContainer, config::DockerConfig)
"""
function build_docker_image(container::DockerContainer, config::DockerConfig)
    docker_image = docker_image_name(config.image)
    if haskey(config.read_only_maps, "/") || haskey(config.read_write_maps, "/")
        throw(ArgumentError("you cannot provide a mapping for /"))
    end
    mktempdir() do build_directory
        cd(build_directory) do
            rm("Dockerfile"; force = true, recursive = true)
            dockerfile = _generate_dockerfile(config, build_directory)
            open("Dockerfile", "w") do io
                println(io, strip(dockerfile))
            end
            docker_build_stdout = _get_docker_build_stdout(config)
            docker_build_stderr = _get_docker_build_stderr(config)
            cleanup(container)
            run(
                pipeline(
                    `docker build --label $(docker_image_label(container)) -t $(docker_image) .`;
                    stdin = Base.devnull,
                    stdout = docker_build_stdout,
                    stderr = docker_build_stderr,
                )
            )
        end
    end
    return docker_image
end

"""
    construct_container_command(container::DockerContainer, config::DockerConfig, cmd::Cmd)
"""
function construct_container_command(container::DockerContainer,
                                     config::DockerConfig,
                                     cmd::Cmd)
    build_docker_image(container, config)

    container_cmd_string = String[
        "docker", "run",
        "--security-opt=no-new-privileges",       # disable container processes from gaining new privileges
        "--interactive",                          # keep STDIN open even if not attached
        "--label", docker_image_label(container), # set metadata
    ]

    # If we're doing a fully-interactive session, tell it to allocate a psuedo-TTY
    is_interactive = all(
        isa.(
            (config.stdin, config.stdout, config.stderr),
            Base.TTY,
        )
    )
    is_interactive && push!(container_cmd_string, "-t")

    # Start in the right directory
    append!(container_cmd_string, ["--workdir=/home/myuser"])

    # Apply environment mappings from `config`
#     for (k, v) in config.env
#         append!(container_cmd_string, ["-e", "$(k)=$(v)"])
#     end

    push!(container_cmd_string, docker_image_name(config.image))
    append!(container_cmd_string, cmd.exec)

    container_cmd = Cmd(container_cmd_string)

    return container_cmd
end
