# Tutorial

## TL;DR: If you read nothing else, read this

```@meta
CurrentModule = Contour
DocTestSetup = quote
    using Contour
    x = -3:0.01:3
    y = -4:0.02:5
    z = [Float64((xi^2 + yi^2)) for xi in x, yi in y]

    plot(x,y,z) = nothing
end
```

The most common use case for this package is plotting iso lines. Here's a
complete example that lets you do that, while showing off all of the most
important features of the package:

```jldoctest
for cl in levels(contours(x,y,z))
    lvl = level(cl) # the z-value of this contour level
    for line in lines(cl)
        xs, ys = coordinates(line) # coordinates of this line segment
        plot(xs, ys, color=lvl) # pseuod-code; use whatever plotting package you prefer
    end
end

# output

```

## Preface: some test data...

The Contour module expects input data to be on a Cartesian grid, and supports
both uniform and non-uniform grid spacings.  For the following examples, `x` and
`y` are 1D sorted arrays that contain the grid coordinates, and `z` is a matrix
arranged such that `z[xi,yi]` correspond to the location `(x[xi], y[yi])`.

Let's consider the function $z(x,y) = x^2 + y^2$:

```julia
x = -3:0.01:3
y = -4:0.02:5

z = [Float64((xi^2 + yi^2)) for xi in x, yi in y]
```

`x` and `y` don't have to be evenly spaced - they can just as well be (sorted)
arrays of coordinate values.

## Example: plotting isolines

Usually, you'll start by calling [`contours`](@ref):

```jldoctest
c = contours(x,y,z)

# output
Contour.ContourCollection{Contour.ContourLevel{Float64}}
 with 10 level(s).
```

The package is designed so that you shouldn't have to worry about the types of
the outputs - instead, there are functions that let you extract the data you
need. So, instead of simply returning a `Vector{ContourLevel}`, we return a
special object which supports the [`levels`](@ref) function. `levels` in turn
returns a collection of `ContourLevel`s which you can iterate over:

```@meta
DocTestSetup = quote
    using Contour
    x = -3:0.01:3
    y = -4:0.02:5
    z = [Float64((xi^2 + yi^2)) for xi in x, yi in y]
    c = contours(x,y,z)
end
```

```jldoctest
for cl in levels(c)
    # do something
end

# output

```

On each level (`cl` in the snippet above) there are two pieces of information
that can be of interest. You find the $z$-value of the isoline with the
[`level`](@ref) function, while [`lines`](@ref) yields an iterable collection
of line segments (remember that there might be more than one isoline for a given
$z$-value):

```@meta
DocTestSetup = quote
    using Contour
    x = -3:0.01:3
    y = -4:0.02:5
    z = [Float64((xi^2 + yi^2)) for xi in x, yi in y]
    c = contours(x,y,z)
    cl = first(levels(c))
end
```

```jldoctest
level(cl), length(lines(cl))

# output
(3.090909090909091,1)
```

This contour level only had one line. An isoline is represented as a sequence of
vertices, which either starts and ends at the boundaries of the data set, or
closes on itself, in which case the first and last points are equal.

The $x$- and $y$-coordinates of an isoline are extracted using the
[`coordinates`](@ref) function:

```@meta
DocTestSetup = quote
    using Contour
    x = -3:0.01:3
    y = -4:0.02:5
    z = [Float64((xi^2 + yi^2)) for xi in x, yi in y]
    c = contours(x,y,z)
    cl = first(levels(c))
    l = first(lines(cl))
end
```

```jldoctest
l = first(lines(cl))
xs, ys = coordinates(l)

typeof(xs)

# output
Array{Float64,1}
```

Now we understand all the parts of the plotting example at the top:

```@meta
DocTestSetup = quote
    using Contour
    x = -3:0.01:3
    y = -4:0.02:5
    z = [Float64((xi^2 + yi^2)) for xi in x, yi in y]
end
```

```jldoctest
for cl in levels(contours(x,y,z))
    lvl = level(cl) # the z-value of this contour level
    for line in lines(cl)
        xs, ys = coordinates(line) # coordinates of this line segment
        plot(xs, ys, color=lvl) # pseuod-code; use whatever plotting package you prefer
    end
end

# output

```

## Affecting the choice of contour levels

There are several ways to affect the choice of contour levels.

First, you can specify them manually:

```jldoctest
contours(x, y, z, [2,3])

# output
Contour.ContourCollection{Contour.ContourLevel{Float64}}
 with 2 level(s).
```

You can also just specify the number of levels you want, and let the package
choose them:

```jldoctest
contours(x, y, z, 2)

# output
Contour.ContourCollection{Contour.ContourLevel{Float64}}
 with 2 level(s).
```

The package uses [`Contour.contourlevels`](@ref) to choose the levels, so it's
entirely possible to investigate what levels would be traced without doing any
plotting:

```jldoctest
Contour.contourlevels(z, 4)

# output
6.8:6.8:27.2
```

If you only want a single contour level, use the [`contour`](@ref) function
directly - its fourth parameter is the $z$-value at which to trace the isolines:

```jldoctest
contour(x, y, z, 2.3)

# output
Contour.ContourLevel{Float64}
  at 2.3 with 1 line(s)
```