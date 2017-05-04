using Documenter, Contour

makedocs()

deploydocs(
    repo = "github.com/JuliaGeometry/Contour.jl",
    julia = "0.6",
    deps = Deps.pip("pygments", "mkdocs", "python-markdown-math")
)
