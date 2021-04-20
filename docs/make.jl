using DockerSandbox
using Documenter

DocMeta.setdocmeta!(DockerSandbox, :DocTestSetup, :(using DockerSandbox); recursive=true)

makedocs(;
    modules=[DockerSandbox],
    authors="Keno Fischer, Dilum Aluthge, and contributors",
    repo="https://github.com/JuliaContainerization/DockerSandbox.jl/blob/{commit}{path}#{line}",
    sitename="DockerSandbox.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://JuliaContainerization.github.io/DockerSandbox.jl",
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
    repo="github.com/JuliaContainerization/DockerSandbox.jl",
)
