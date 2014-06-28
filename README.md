# Contour

[![Build Status](https://travis-ci.org/tlycken/Contour.jl.svg?branch=master)](https://travis-ci.org/tlycken/Contour.jl)
[![Coverage Status](https://img.shields.io/coveralls/tlycken/Contour.jl.svg?branch=master)](https://coveralls.io/r/tlycken/Contour.jl)

A generic library for tracing contour curves on a scalar 2D field.

The idea with this library is to separate the contouring alghorithm(s) from the various visualization tools, so that all tools can benefit from advances made here - as well as in other applications, independenly of choice of visualization tool. The current implementation use the [marching squares algorithm](http://en.wikipedia.org/wiki/Marching_squares) to calculate contours.

There are [ongoing](https://github.com/tlycken/Contour.jl/issues/1) [api-discussions](https://github.com/tlycken/Contour.jl/issues/2), so the API of this library should not be considered stable yet. As a consequence, it is not yet published to METADATA, but can still be downloaded through `Pkg.clone("https://github.com/tlycken/Contour.jl.git")` if you want to kick the tires or help out. Hopefully, [this discussion on the users list](https://groups.google.com/forum/?fromgroups=#!topic/julia-dev/fqwnyOojRdg) concerning a generic package for geometric objects like points and lines will yield something useful, in which case this package will be adjusted to use those types.

## Usage Examples

The Contour module currently expects input data to be on a Cartesian grid,
and supports both uniform and non-uniform grid spacings.  For the following
examples, `x` and `y` are 1D sorted arrays that contain the grid coordinates,
and `z` is a matrix arranged such that `z[xi,yi]` correspond to the location
`(x[xi], y[yi])`.


```julia
x = [-3:0.01:3]
y = [-4:0.02:5]

z = [(xi^2 + yi^2)::Float64 for xi in x, yi in y]
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
julia> c.level
4.0

julia> c.lines
1-element Array{Curve2{Float64},1}:
 Curve2{Float64}([[0.0,2.0],[0.0,2.0],[-1.73472e-18,2.0],[-0.01,1.99997],
 [-0.02,1.9999],[-0.03,1.99977],[-0.04,1.9996],[-0.05,1.99937],[-0.06,1.9991],
 [-0.07,1.99877]  …  [0.09,1.99796],[0.08,1.99839],[0.07,1.99877],[0.06,1.9991],
 [0.05,1.99937],[0.04,1.9996],[0.03,1.99977],[0.02,1.9999],[0.01,1.99997],
 [0.0,2.0]])
 ```

We can also find the contours at multiple levels using `contours`, 
which returns an array of `ContourLevel` types. 

```julia
julia> h = [4.0, 5.0, 6.0];
julia> c = contours(x, y, z, h)
3-element Array{ContourLevel,1}:
 ContourLevel(4.0,[Curve2{Float64}([[0.0,2.0],…,[0.0,2.0]])])
 ContourLevel(5.0,[Curve2{Float64}([[0.28,-2.21846], …,[0.28,-2.21846]])])
 ContourLevel(6.0,[Curve2{Float64}([[-0.64,-2.36439],…,[-0.64,-2.36439]])])
```

Instead of specifying all the levels explicitly, we can also
specify the number of levels we want.  

```julia
julia> N = 3;
julia> c = contours(x, y, z, N)
3-element Array{ContourLevel,1}:
 ContourLevel(8.5,[Curve2{Float64}([[0.62,2.84877],…,[0.62,2.84877]])]) 
 ContourLevel(17.0,[Curve2{Float64}([[3.0,2.82841],…,[3.0,-2.82841]])])
 ContourLevel(25.5,[Curve2{Float64}([[3.0,4.06201],…,[-3.0,4.06201]])])
```
Currently, `contours` will pick `N` levels that evenly spans the
extrema of `z`.

## Credits
The main authors of this package are [Darwin Darakananda](https://github.com/darwindarak/) and [Tomas Lycken](https://github.com/tlycken).
