"""
    with_container(f::Function, ::Type{T} = DockerContainer) where {T <: DockerContainer}
"""
function with_container(f::Function,
                        container_type::Type{T} = DockerContainer) where {T <: DockerContainer}
    container = container_type()
    return with_container(f, container)
end

"""
    with_container(f::Function, container::DockerContainer)
"""
function with_container(f::Function, container::DockerContainer)
    try
        return f(container)
    finally
        cleanup(container)
    end
end
