using Docker
using Documenter

DocMeta.setdocmeta!(Docker, :DocTestSetup, :(using Docker); recursive=true)

makedocs(;
    modules=[Docker],
    authors="Keno Fischer, Dilum Aluthge, and contributors",
    repo="https://github.com/JuliaContainerization/Docker.jl/blob/{commit}{path}#{line}",
    sitename="Docker.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://JuliaContainerization.github.io/Docker.jl",
        assets=String[],
    ),
    pages=[
        "Home"                => "index.md",
        "Prerequisites"       => "prerequisites.md",
        "Examples"            => "examples.md",
        "Public API"          => "public.md",
        "Internals (Private)" => "internals.md",
    ],
    strict=true,
)

deploydocs(;
    repo="github.com/JuliaContainerization/Docker.jl",
)
