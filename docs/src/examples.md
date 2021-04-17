```@meta
CurrentModule = Docker
```

# Examples

```@example
using Docker

config = DockerConfig(; image = "julia:buster");

with_container() do container
    code = """
    println("This was a success.")
    """
    run(container, config, `julia -e $(code)`)
end
```

```julia
julia> using Docker

julia> config = DockerConfig(;
           image = "julia:buster",
           Base.stdin,
           Base.stdout,
           Base.stderr,
       );

julia> with_container() do container
           run(container, config, `/bin/bash`)
       end
```
