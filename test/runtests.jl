using Contour, Test

include("verify_vertices.jl")
include("interface.jl")

# @show detect_ambiguities(Base, Contour) # should be zero but there are a few stragglers in the imports

#issue 59
@inferred collect(())
