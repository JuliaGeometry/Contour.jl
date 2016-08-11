module InterfaceTests

export setup

function setup()
    nx, ny = 10, 10

    xs = sort!(rand(nx))
    ys = sort!(rand(ny))
    zs = rand(nx,ny)

    xs, ys, zs
end

module Current

using Contour, Base.Test, ..InterfaceTests

xs, ys, zs = setup()

cs = @inferred contours(xs,ys,zs)
for c in levels(cs)
    for l in lines(c)
        x,y = coordinates(l)
        @assert typeof(x) == typeof(y) == Vector{Float64}
    end
end

end # Current

module Legacy

using Contour, Base.Test
using ..InterfaceTests

xs, ys, zs = setup()

# v"0.0.7"
cs = @inferred contours(xs, ys, zs)
for c in levels(cs)
    for l in c.lines
        x,y = @inferred coordinates(l)
        @assert typeof(x) == typeof(y) == Vector{Float64}
    end
end

c2 = @inferred contour(xs, ys, zs, 0.3)
for l in c2.lines
    x,y = @inferred coordinates(l)
    @assert typeof(x) == typeof(y) == Vector{Float64}
end

end # Legacy

end # InterfaceTests
