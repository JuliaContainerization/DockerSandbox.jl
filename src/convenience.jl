"""
    with_container(f::Function, ::Type{<:DockerContainer} = DockerContainer; kwargs...)
"""
function with_container(f::F,
                        ::Type{T} = DockerContainer;
                        kwargs...) where {F <: Function, T <: DockerContainer}
    container = T(; kwargs...)
    try
        return f(container)
    finally
        cleanup(container)
    end
end
