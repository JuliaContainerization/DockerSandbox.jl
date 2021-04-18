```@meta
CurrentModule = Docker
```

# Examples

## Simple Example

```@example
using Docker

config = DockerConfig(; image = "julia:latest");

with_container() do container
    code = """
    println("Hello world!")
    """
    run(container, config, `julia -e $(code)`)
end
```

## Interactive Example

```julia
julia> using Docker

julia> config = DockerConfig(;
           image = "julia:latest",
           Base.stdin,
           Base.stdout,
           Base.stderr,
       );

julia> with_container() do container
           run(container, config, `/bin/bash`)
       end
```
