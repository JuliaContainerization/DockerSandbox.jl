"""
    with_container(f::Function, ::Type{T} = DockerContainer) where {T <: DockerContainer}
"""
function with_container(f::Function,
                        ::Type{T} = DockerContainer) where {T <: DockerContainer}
    container = T()
    return with_container(f, container)
end

"""
    with_container(f::Function, container::DockerContainer)
"""
function with_container(f::Function, container::DockerContainer)
    cleanup(container)
    try
        return f(container)
    finally
        cleanup(container)
    end
end
