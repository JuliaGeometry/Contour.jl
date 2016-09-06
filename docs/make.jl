using Documenter, Contour

makedocs()

deploydocs(
    repo = "github.com/tlycken/Contour.jl",
    julia = "0.5",
    deps = Deps.pip("pygments", "mkdocs", "python-markdown-math")
)
