"""
    cleanup(container::DockerContainer)
"""
function cleanup(container::DockerContainer)
    label = docker_image_label(container)
    success(`docker system prune --all --force --filter=label=$(label)`)
    return nothing
end
