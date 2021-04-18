using Docker
using Test

import Pkg
import TOML

include("no_nonstdlib_deps.jl")
include("docker_is_installed.jl")
include("errors.jl")
include("with_container.jl")
include("read_only_maps.jl")
include("read_write_maps.jl")
