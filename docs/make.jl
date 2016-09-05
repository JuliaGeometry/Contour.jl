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
