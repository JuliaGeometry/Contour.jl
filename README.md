# Contour

[![Build Status](https://travis-ci.org/tlycken/Contour.jl.svg?branch=master)](https://travis-ci.org/tlycken/Contour.jl)
[![Contour](http://pkg.julialang.org/badges/Contour_0.3.svg)](http://pkg.julialang.org/?pkg=Contour&ver=0.3)
[![Contour](http://pkg.julialang.org/badges/Contour_0.4.svg)](http://pkg.julialang.org/?pkg=Contour&ver=0.4)
[![Coverage Status](https://img.shields.io/coveralls/tlycken/Contour.jl.svg?branch=master)](https://coveralls.io/r/tlycken/Contour.jl)

A generic library for tracing contour curves on a scalar 2D field.

The idea with this library is to separate the contouring algorithm(s) from the various visualization tools, so that all tools can benefit from advances made here - as well as in other applications, independently of choice of visualization tool. The current implementation uses the [marching squares algorithm](http://en.wikipedia.org/wiki/Marching_squares) to calculate contours.

## Usage Examples

The Contour module currently expects input data to be on a Cartesian grid,
and supports both uniform and non-uniform grid spacings.  For the following
examples, `x` and `y` are 1D sorted arrays that contain the grid coordinates,
and `z` is a matrix arranged such that `z[xi,yi]` correspond to the location
`(x[xi], y[yi])`.

```julia
x = -3:0.01:3
y = -4:0.02:5

z = [Float64((xi^2 + yi^2)) for xi in x, yi in y]
```

Let's find the contour line corresponding to `z = 4.0`:

```julia
h = 4.0
c = contour(x, y, z, h)
```

This returns a `ContourLevel` type containing the contour value as well
an array of lines.  In the current example, we expect a single line that
traces out a circle with radius 2:

```julia
julia> level(c)
4.0

julia> lines(c)
1 contour lines
```

The format of the output data is intented to give as extensive information as possible about the contour line. However, it can admittedly be a little difficult to use this information in an application. For example, if we want to plot a contour level, it is much more practical to have the coordinates of the contour vertices as two lists instead of this complicated structure. No worries, just use `coordinates`:

```julia
for l in lines(c) # each contour level can be represented by multiple lines
    xs, ys = coordinates(l) # xs and ys are now Vectors of equal length
    plot(xs, ys) # using your favorite plotting tool
end
```

`Contour.jl` makes sure that the coordinates are ordered correctly, and contours that close on themselves are given cyclically, so that e.g. `xs[1]==xs[end]` - in other words, plotting the contour does not require you to add the first point at the end manually to close the curve.

We can also find the contours at multiple levels using `contours`,
which returns an array of `ContourLevel` types.

```julia
julia> h = [4.0, 5.0, 6.0];
julia> c = contours(x, y, z, h)
Collection of 3 levels.
```

Instead of specifying all the levels explicitly, we can also
specify the number of levels we want.  

```julia
julia> N = 3;
julia> c = contours(x, y, z, N)
Collection of 3 levels
```

`contours` will pick `N` levels that evenly span the extrema of `z`.

## Credits
The main authors of this package are [Darwin Darakananda](https://github.com/darwindarak/) and [Tomas Lycken](https://github.com/tlycken).
