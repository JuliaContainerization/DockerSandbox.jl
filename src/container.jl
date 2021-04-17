function docker_image_label(container::DockerContainer)
    return string("org.julialang.docker.jl=", container.label)
end

function cleanup(container::DockerContainer)
    label = docker_image_label(container)
    return success(`docker system prune --force --filter=label=$(label)`)
end

function build_container_command(container::DockerContainer,
                                 config::DockerConfig,
                                 user_cmd::Cmd)
    cmd_string = String[
        "docker",
        "run",
        "-i",
        "--label",
        docker_image_label(container),
    ]

    # If we're doing a fully-interactive session, tell it to allocate a psuedo-TTY
    is_interactive = all(
        isa.(
            (config.stdin, config.stdout, config.stderr),
            Base.TTY,
        )
    )
    is_interactive && push!(cmd_string, "-t")

    # Start in the right directory
    append!(cmd_string, ["-w", config.pwd])

    # Add in read-only mappings (skipping the rootfs)
#     for (dst, src) in config.read_only_maps
#         if dst == "/"
#             continue
#         end
#         append!(cmd_string, ["-v", "$(src):$(dst):ro"])
#     end

    # Add in read-write mappings
#     for (dst, src) in config.read_write_maps
#         append!(cmd_string, ["-v", "$(src):$(dst)"])
#     end

    # Apply environment mappings, first from `config`, next from `user_cmd`.
#     for (k, v) in config.env
#         append!(cmd_string, ["-e", "$(k)=$(v)"])
#     end
    # if user_cmd.env !== nothing
    #     for pair in user_cmd.env
    #         append!(cmd_string, ["-e", pair])
    #     end
    # end

    # Add in entrypoint, if it is set
    # if config.entrypoint !== nothing
    #     append!(cmd_string, ["--entrypoint", config.entrypoint])
    # end

    # Finally, append the docker image name user-requested command string
    push!(cmd_string, config.image)
    append!(cmd_string, user_cmd.exec)

    docker_cmd = Cmd(cmd_string)

    # If the user has asked that this command be allowed to fail silently, pass that on
    # if user_cmd.ignorestatus
    #     docker_cmd = ignorestatus(docker_cmd)
    # end

    return docker_cmd
end
