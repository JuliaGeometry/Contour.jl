# Contour.jl

```@meta
CurrentModule = Contour
```

Contour.jl uses the [marching squares algorithm](http://en.wikipedia.org/wiki/Marching_squares).

This algorithm expects input data to be on a Cartesian grid, and supports both
uniform and non-uniform grid spacings.  For the following examples, `x` and `y`
are 1D sorted arrays that contain the grid coordinates, and `z` is a matrix
arranged such that `z[xi,yi]` correspond to the location `(x[xi], y[yi])`.

```@meta
DocTestSetup = quote
    using Contour
    x = -3:0.01:3
    y = -4:0.02:5
    z = [Float64((xi^2 + yi^2)) for xi in x, yi in y]
end
```

```jldoctest
c = contours(x,y,z)

#output
Contour.ContourCollection{Contour.ContourLevel{Float64}}
 with 10 level(s).
```