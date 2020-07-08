using Contour, Test

include("verify_vertices.jl")
include("interface.jl")

@test length(detect_ambiguities(Base, Contour)) <= 4 # should be zero but there are a few stragglers in the imports

#issue 59
@inferred collect(())
