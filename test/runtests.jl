using DockerSandbox
using Test

import Pkg
import TOML

include("utils.jl")

include("no_nonstdlib_deps.jl")
include("docker_is_installed.jl")

include("add_capabilities.jl")
include("environment_variables.jl")
# include("errors.jl")
include("read_only_maps.jl")
include("read_write_maps.jl")
include("with_container.jl")

include("errors.jl")
