for f in (:run, :success)
    @eval begin
        """
            $($f)(container::DockerContainer, config::DockerConfig, user_cmd::Cmd; kwargs...)
        """
        function $f(container::DockerContainer,
                    config::DockerConfig,
                    cmd::Cmd;
                    kwargs...)
            container_cmd = build_container_command(
                container,
                config,
                cmd,
            )
            docker_cmd = pipeline(
                container_cmd;
                config.stdin,
                config.stdout,
                config.stderr,
            )
            if config.verbose
                @info("Running sandboxed command", cmd.exec)
            end
            return $f(docker_cmd; kwargs...)
        end
    end
end
