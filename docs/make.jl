import Documenter

Documenter.deploydocs(
    julia = "nightly",
    repo = "github.com/bramtayl/ValuedTuples.jl.git",
    target = "build",
    deps = nothing,
    make = nothing
)
