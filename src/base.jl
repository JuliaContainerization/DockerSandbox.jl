for f in (:run, :success)
    @eval begin
        function $f(container::DockerContainer,
                    config::DockerConfig,
                    user_cmd::Cmd;
                    kwargs...)
            cmd = pipeline(
                build_container_command(container, config, user_cmd);
                config.stdin,
                config.stdout,
                config.stderr,
            )
            if config.verbose
                @info("Running sandboxed command", user_cmd.exec)
            end
            return $f(cmd; kwargs...)
        end
    end
end
