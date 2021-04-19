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

"""
    cleanup_container(container::DockerContainer)
"""
function cleanup_container(container::DockerContainer)
    label = docker_image_label(container)
    success(`docker system prune --force --filter=label=$(label)`)
    return nothing
end

function _generate_dockerfile(config::DockerConfig)
    if config.platform === :linux
        return """
        FROM --platform=linux $(config.image)
        RUN usermod --lock root
        RUN groupadd --system myuser
        RUN useradd --create-home --shell /bin/bash --system --gid myuser myuser
        USER myuser
        """
    else
        msg = "Invalid value for config.platform: $(config.platform)"
        throw(ArgumentError(msg))
    end
end

"""
    build_docker_image(config::DockerConfig)
"""
function build_docker_image(config::DockerConfig)
    docker_image = docker_image_name(config.image)
    mktempdir() do tmp_dir
        cd(tmp_dir) do
            rm("Dockerfile"; force = true, recursive = true)
            dockerfile = _generate_dockerfile(config)
            open("Dockerfile", "w") do io
                println(io, strip(dockerfile))
            end
            if config.docker_build_stdout === nothing
                if config.verbose
                    docker_build_stdout = Base.stdout
                else
                    docker_build_stdout = Base.devnull
                end
            else
                docker_build_stdout = config.docker_build_stdout
            end
            if config.docker_build_stderr === nothing
                if config.verbose
                    docker_build_stderr = Base.stderr
                else
                    docker_build_stderr = Base.devnull
                end
            else
                docker_build_stderr = config.docker_build_stderr
            end
            (docker_build_stdout isa IO) || throw(ArgumentError("docker_build_stdout must be an IO"))
            (docker_build_stderr isa IO) || throw(ArgumentError("docker_build_stderr must be an IO"))
            run(
                pipeline(
                    `docker build -t $(docker_image) .`;
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
    build_docker_image(config)

    container_cmd_string = String[
        "docker",
        "run",
        "--security-opt=no-new-privileges",       # disable container processes from gaining new privileges
        "--cap-drop=all",                         # drop all capabilities
        "--interactive",                          # keep STDIN open even if not attached
        "--label", docker_image_label(container), # set metadata
        "--rm=true",                              # automatically remove the container when it exits
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

    # Add in read-only mappings
    if config.read_only_maps !== nothing
        for (dst, src) in pairs(config.read_only_maps)
            if dst == "/"
                throw(ArgumentError("Cannot provide a mapping for /"))
            else
                append!(container_cmd_string, ["-v", "$(src):$(dst):ro"])
            end
        end
    end

    # Add in read-write mappings
    if config.read_write_maps !== nothing
        for (dst, src) in pairs(config.read_write_maps)
            if dst == "/"
                throw(ArgumentError("Cannot provide a mapping for /"))
            else
                append!(container_cmd_string, ["-v", "$(src):$(dst)"])
            end
        end
    end

    # Apply environment mappings from `config`
    if config.env !== nothing
        for (k, v) in pairs(config.env)
            append!(container_cmd_string, ["-e", "$(k)=$(v)"])
        end
    end

    push!(container_cmd_string, docker_image_name(config.image))
    append!(container_cmd_string, cmd.exec)

    container_cmd = Cmd(container_cmd_string)

    return container_cmd
end
