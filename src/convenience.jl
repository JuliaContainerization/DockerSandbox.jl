function with_container(f::Function,
                        container_type::Type{T} = DockerContainer) where {T}
    container = container_type()
    return with_container(f, container)
end

function with_container(f::Function, container::DockerContainer)
    try
        return f(container)
    finally
        cleanup(container)
    end
end
