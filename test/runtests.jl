using ValuedTuples

import Documenter
Documenter.makedocs(
    modules = [ValuedTuples],
    format = :html,
    sitename = "ValuedTuples.jl",
    root = joinpath(dirname(dirname(@__FILE__)), "docs"),
    pages = Any["Home" => "index.md"],
    strict = true,
    linkcheck = true,
    checkdocs = :exports,
    authors = "Brandon Taylor"
)
