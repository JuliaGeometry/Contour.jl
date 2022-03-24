using Contour, Test

@test length(detect_ambiguities(Base, Contour)) == 0

include("verify_vertices.jl")
include("interface.jl")


#issue 59
@inferred collect(())
