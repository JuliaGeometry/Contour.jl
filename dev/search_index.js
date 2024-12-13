var documenterSearchIndex = {"docs":
[{"location":"reference/#Entry-points","page":"Reference","title":"Entry points","text":"","category":"section"},{"location":"reference/","page":"Reference","title":"Reference","text":"contour\ncontours","category":"page"},{"location":"reference/#Contour.contour","page":"Reference","title":"Contour.contour","text":"contour(x, y, z, level::Number)\ncontour(x, y, z, level::Number, VT::Type)\n\nTrace a single contour level, indicated by the argument level. The extracted vertex type maybe be specified by VT.\n\nYou'll usually call lines on the output of contour, and then iterate over the result.\n\n\n\n\n\n","category":"function"},{"location":"reference/#Contour.contours","page":"Reference","title":"Contour.contours","text":"contours returns a set of isolines.\n\nYou'll usually call levels on the output of contours.\n\n\n\n\n\n","category":"function"},{"location":"reference/#Accessors","page":"Reference","title":"Accessors","text":"","category":"section"},{"location":"reference/","page":"Reference","title":"Reference","text":"level\nlevels\nlines\ncoordinates\nvertices","category":"page"},{"location":"reference/#Contour.level","page":"Reference","title":"Contour.level","text":"level(c) Indicates the z-value at which the contour level c was traced.\n\n\n\n\n\n","category":"function"},{"location":"reference/#Contour.levels","page":"Reference","title":"Contour.levels","text":"Turns the output of contours into an iterable with each of the traced contour levels. Each of the objects support level, coordinates, and vertices.\n\n\n\n\n\n","category":"function"},{"location":"reference/#Contour.lines","page":"Reference","title":"Contour.lines","text":"lines(c) Extracts an iterable collection of isolines from a contour level. Use coordinates or vertices to get the coordinates of a line.\n\n\n\n\n\n","category":"function"},{"location":"reference/#Contour.coordinates","page":"Reference","title":"Contour.coordinates","text":"coordinates(c) Returns the coordinates of the vertices of the contour line as a tuple of lists.\n\n\n\n\n\n","category":"function"},{"location":"reference/#Contour.vertices","page":"Reference","title":"Contour.vertices","text":"vertices(c)\n\nReturns the vertices of a contour line as a vector of 2-element tuples.\n\n\n\n\n\n","category":"function"},{"location":"reference/#Utilities","page":"Reference","title":"Utilities","text":"","category":"section"},{"location":"reference/","page":"Reference","title":"Reference","text":"Contour.contourlevels","category":"page"},{"location":"reference/#Contour.contourlevels","page":"Reference","title":"Contour.contourlevels","text":"contourlevels(z,n) Examines the values of z and chooses n evenly spaced levels to trace.\n\n\n\n\n\n","category":"function"},{"location":"#Introduction","page":"Introduction","title":"Introduction","text":"","category":"section"},{"location":"","page":"Introduction","title":"Introduction","text":"Contour.jl uses the marching squares algorithm to find isolines of a discrete data set representing a function z = f(x y).","category":"page"},{"location":"tutorial/#Tutorial","page":"Tutorial","title":"Tutorial","text":"","category":"section"},{"location":"tutorial/#TL;DR:-If-you-read-nothing-else,-read-this","page":"Tutorial","title":"TL;DR: If you read nothing else, read this","text":"","category":"section"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"CurrentModule = Contour","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"The most common use case for this package is plotting iso lines. Here's a complete example that lets you do that, while showing off all of the most important features of the package:","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"using Contour # hide\nx = -3:0.01:3 # hide\ny = -4:0.02:5 # hide\nz = [Float64((xi^2 + yi^2)) for xi in x, yi in y] # hide\nplot(args...;kwargs...) = nothing # hide\nfor cl in levels(contours(x,y,z))\n    lvl = level(cl) # the z-value of this contour level\n    for line in lines(cl)\n        xs, ys = coordinates(line) # coordinates of this line segment\n        plot(xs, ys, color=lvl) # pseuod-code; use whatever plotting package you prefer\n    end\nend","category":"page"},{"location":"tutorial/#Preface:-some-test-data...","page":"Tutorial","title":"Preface: some test data...","text":"","category":"section"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"The Contour module expects input data to be on a Cartesian grid, and supports uniform  and non-uniform grid spacings, as well as general curvilinear grids (where x and y are matrices).  ","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"For the following examples, x and y are 1D sorted arrays that contain the grid coordinates, and z is a matrix arranged such that z[xi,yi] correspond to the location (x[xi], y[yi]).","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"Let's consider the function z(xy) = x^2 + y^2:","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"x = -3:0.01:3\ny = -4:0.02:5\n\nz = [Float64((xi^2 + yi^2)) for xi in x, yi in y]\nnothing # hide","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"x and y don't have to be evenly spaced - they can just as well be (sorted) arrays of coordinate values.","category":"page"},{"location":"tutorial/#Example:-plotting-isolines","page":"Tutorial","title":"Example: plotting isolines","text":"","category":"section"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"Usually, you'll start by calling contours:","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"using Contour # hide\nx = -3:0.01:3 # hide\ny = -4:0.02:5 # hide\nz = [Float64((xi^2 + yi^2)) for xi in x, yi in y] # hide\nc = contours(x,y,z)\nnothing # hide","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"The package is designed so that you shouldn't have to worry about the types of the outputs - instead, there are functions that let you extract the data you need. So, instead of simply returning a Vector{ContourLevel}, we return a special object which supports the levels function. levels in turn returns an iterable, where each item represents a contour level:","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"using Contour # hide\nx = -3:0.01:3 # hide\ny = -4:0.02:5 # hide\nz = [Float64((xi^2 + yi^2)) for xi in x, yi in y] # hide\nc = contours(x,y,z) # hide\nfor cl in levels(c)\n    # do something\nend","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"On each level (cl in the snippet above) there are two pieces of information that can be of interest. You find the z-value of the isoline with the level function, while lines yields an iterable collection of line segments (remember that there might be more than one isoline for a given z-value):","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"using Contour # hide\nx = -3:0.01:3 # hide\ny = -4:0.02:5 # hide\nz = [Float64((xi^2 + yi^2)) for xi in x, yi in y] # hide\nc = contours(x,y,z) # hide\ncl = first(levels(c)) # hide\nlevel(cl) # the z-value of the current isoline collection\nlines(cl) # an iterable collection of isolines\nnothing # hide","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"This contour level only had one line. An isoline is represented as a sequence of vertices, which either starts and ends at the boundaries of the data set, or closes on itself, in which case the first and last points are equal.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"The x- and y-coordinates of an isoline can be extracted using the coordinates or vertices functions:","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"using Contour # hide\nx = -3:0.01:3 # hide\ny = -4:0.02:5 # hide\nz = [Float64((xi^2 + yi^2)) for xi in x, yi in y] # hide\nc = contours(x,y,z) # hide\ncl = first(levels(c)) # hide\nl = first(lines(cl))\nxs, ys = coordinates(l)\nx_y_pairs = vertices(l)\nnothing # hide","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"Now we understand all the parts of the plotting example at the top:","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"using Contour # hide\nx = -3:0.01:3 # hide\ny = -4:0.02:5 # hide\nz = [Float64((xi^2 + yi^2)) for xi in x, yi in y] # hide\nplot(args...; kwargs...) = nothing # hide\nfor cl in levels(contours(x,y,z))\n    lvl = level(cl) # the z-value of this contour level\n    for line in lines(cl)\n        xs, ys = coordinates(line) # coordinates of this line segment\n        plot(xs, ys, color=lvl) # pseuod-code; use whatever plotting package you prefer\n    end\nend","category":"page"},{"location":"tutorial/#Affecting-the-choice-of-contour-levels","page":"Tutorial","title":"Affecting the choice of contour levels","text":"","category":"section"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"There are several ways to affect the choice of contour levels.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"First, you can specify them manually:","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"using Contour # hide\nx = -3:0.01:3 # hide\ny = -4:0.02:5 # hide\nz = [Float64((xi^2 + yi^2)) for xi in x, yi in y] # hide\ncontours(x, y, z, [2,3])\nnothing # hide","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"You can also just specify the number of levels you want, and let the package choose them:","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"using Contour # hide\nx = -3:0.01:3 # hide\ny = -4:0.02:5 # hide\nz = [Float64((xi^2 + yi^2)) for xi in x, yi in y] # hide\ncontours(x, y, z, 2)\nnothing # hide","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"The package uses Contour.contourlevels to choose the levels, so it's entirely possible to investigate what levels would be traced without doing any plotting:","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"using Contour # hide\nx = -3:0.01:3 # hide\ny = -4:0.02:5 # hide\nz = [Float64((xi^2 + yi^2)) for xi in x, yi in y] # hide\nContour.contourlevels(z, 4)\nnothing # hide","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"If you only want a single contour level, use the contour function directly - its fourth parameter is the z-value at which to trace the isolines:","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"using Contour # hide\nx = -3:0.01:3 # hide\ny = -4:0.02:5 # hide\nz = [Float64((xi^2 + yi^2)) for xi in x, yi in y] # hide\ncontour(x, y, z, 2.3)\nnothing # hide","category":"page"}]
}
