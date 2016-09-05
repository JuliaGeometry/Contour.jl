using Documenter, Contour

makedocs(
    format = Documenter.Formats.HTML,
    sitename = "Contour.jl",
    pages = [
        "index.md",
        "tutorial.md",
        "reference.md"
    ]
)

deploydocs(
    repo = "github.com/tlycken/Contour.jl",
    julia = "0.5"
)
