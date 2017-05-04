using Documenter, Contour

makedocs(
    modules = [Contour],
    format = :html,
    sitename = "Contour.jl",
    pages = Any[
        "Introduction" => "index.md",
        "Tutorial" => "tutorial.md",
        "Reference" => "reference.md",
    ]
)

deploydocs(
    repo = "github.com/JuliaGeometry/Contour.jl.git",
    target = "build",
    julia = "0.6",
    deps = nothing,
    make = nothing
)
