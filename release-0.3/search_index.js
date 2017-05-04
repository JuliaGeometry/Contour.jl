var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Introduction",
    "title": "Introduction",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#Introduction-1",
    "page": "Introduction",
    "title": "Introduction",
    "category": "section",
    "text": "Contour.jl uses the marching squares algorithm to find isolines of a discrete data set representing a function z = f(x y)."
},

{
    "location": "tutorial.html#",
    "page": "Tutorial",
    "title": "Tutorial",
    "category": "page",
    "text": ""
},

{
    "location": "tutorial.html#Tutorial-1",
    "page": "Tutorial",
    "title": "Tutorial",
    "category": "section",
    "text": ""
},

{
    "location": "tutorial.html#TL;DR:-If-you-read-nothing-else,-read-this-1",
    "page": "Tutorial",
    "title": "TL;DR: If you read nothing else, read this",
    "category": "section",
    "text": "CurrentModule = ContourThe most common use case for this package is plotting iso lines. Here's a complete example that lets you do that, while showing off all of the most important features of the package:using Contour # hide\nx = -3:0.01:3 # hide\ny = -4:0.02:5 # hide\nz = [Float64((xi^2 + yi^2)) for xi in x, yi in y] # hide\nplot(args...;kwargs...) = nothing # hide\nfor cl in levels(contours(x,y,z))\n    lvl = level(cl) # the z-value of this contour level\n    for line in lines(cl)\n        xs, ys = coordinates(line) # coordinates of this line segment\n        plot(xs, ys, color=lvl) # pseuod-code; use whatever plotting package you prefer\n    end\nend"
},

{
    "location": "tutorial.html#Preface:-some-test-data...-1",
    "page": "Tutorial",
    "title": "Preface: some test data...",
    "category": "section",
    "text": "The Contour module expects input data to be on a Cartesian grid, and supports both uniform and non-uniform grid spacings.  For the following examples, x and y are 1D sorted arrays that contain the grid coordinates, and z is a matrix arranged such that z[xi,yi] correspond to the location (x[xi], y[yi]).Let's consider the function z(xy) = x^2 + y^2:x = -3:0.01:3\ny = -4:0.02:5\n\nz = [Float64((xi^2 + yi^2)) for xi in x, yi in y]\nnothing # hidex and y don't have to be evenly spaced - they can just as well be (sorted) arrays of coordinate values."
},

{
    "location": "tutorial.html#Example:-plotting-isolines-1",
    "page": "Tutorial",
    "title": "Example: plotting isolines",
    "category": "section",
    "text": "Usually, you'll start by calling contours:using Contour # hide\nx = -3:0.01:3 # hide\ny = -4:0.02:5 # hide\nz = [Float64((xi^2 + yi^2)) for xi in x, yi in y] # hide\nc = contours(x,y,z)\nnothing # hideThe package is designed so that you shouldn't have to worry about the types of the outputs - instead, there are functions that let you extract the data you need. So, instead of simply returning a Vector{ContourLevel}, we return a special object which supports the levels function. levels in turn returns an iterable, where each item represents a contour level:using Contour # hide\nx = -3:0.01:3 # hide\ny = -4:0.02:5 # hide\nz = [Float64((xi^2 + yi^2)) for xi in x, yi in y] # hide\nc = contours(x,y,z) # hide\nfor cl in levels(c)\n    # do something\nendOn each level (cl in the snippet above) there are two pieces of information that can be of interest. You find the z-value of the isoline with the level function, while lines yields an iterable collection of line segments (remember that there might be more than one isoline for a given z-value):using Contour # hide\nx = -3:0.01:3 # hide\ny = -4:0.02:5 # hide\nz = [Float64((xi^2 + yi^2)) for xi in x, yi in y] # hide\nc = contours(x,y,z) # hide\ncl = first(levels(c)) # hide\nlevel(cl) # the z-value of the current isoline collection\nlines(cl) # an iterable collection of isolines\nnothing # hideThis contour level only had one line. An isoline is represented as a sequence of vertices, which either starts and ends at the boundaries of the data set, or closes on itself, in which case the first and last points are equal.The x- and y-coordinates of an isoline are extracted using the coordinates function:using Contour # hide\nx = -3:0.01:3 # hide\ny = -4:0.02:5 # hide\nz = [Float64((xi^2 + yi^2)) for xi in x, yi in y] # hide\nc = contours(x,y,z) # hide\ncl = first(levels(c)) # hide\nl = first(lines(cl))\nxs, ys = coordinates(l)\nnothing # hideNow we understand all the parts of the plotting example at the top:using Contour # hide\nx = -3:0.01:3 # hide\ny = -4:0.02:5 # hide\nz = [Float64((xi^2 + yi^2)) for xi in x, yi in y] # hide\nplot(args...; kwargs...) = nothing # hide\nfor cl in levels(contours(x,y,z))\n    lvl = level(cl) # the z-value of this contour level\n    for line in lines(cl)\n        xs, ys = coordinates(line) # coordinates of this line segment\n        plot(xs, ys, color=lvl) # pseuod-code; use whatever plotting package you prefer\n    end\nend"
},

{
    "location": "tutorial.html#Affecting-the-choice-of-contour-levels-1",
    "page": "Tutorial",
    "title": "Affecting the choice of contour levels",
    "category": "section",
    "text": "There are several ways to affect the choice of contour levels.First, you can specify them manually:using Contour # hide\nx = -3:0.01:3 # hide\ny = -4:0.02:5 # hide\nz = [Float64((xi^2 + yi^2)) for xi in x, yi in y] # hide\ncontours(x, y, z, [2,3])\nnothing # hideYou can also just specify the number of levels you want, and let the package choose them:using Contour # hide\nx = -3:0.01:3 # hide\ny = -4:0.02:5 # hide\nz = [Float64((xi^2 + yi^2)) for xi in x, yi in y] # hide\ncontours(x, y, z, 2)\nnothing # hideThe package uses Contour.contourlevels to choose the levels, so it's entirely possible to investigate what levels would be traced without doing any plotting:using Contour # hide\nx = -3:0.01:3 # hide\ny = -4:0.02:5 # hide\nz = [Float64((xi^2 + yi^2)) for xi in x, yi in y] # hide\nContour.contourlevels(z, 4)\nnothing # hideIf you only want a single contour level, use the contour function directly - its fourth parameter is the z-value at which to trace the isolines:using Contour # hide\nx = -3:0.01:3 # hide\ny = -4:0.02:5 # hide\nz = [Float64((xi^2 + yi^2)) for xi in x, yi in y] # hide\ncontour(x, y, z, 2.3)\nnothing # hide"
},

{
    "location": "reference.html#",
    "page": "Reference",
    "title": "Reference",
    "category": "page",
    "text": ""
},

{
    "location": "reference.html#Contour.contour",
    "page": "Reference",
    "title": "Contour.contour",
    "category": "Function",
    "text": "contour(x, y, z, level::Number) Trace a single contour level, indicated by the argument level.\n\nYou'll usually call lines on the output of contour, and then iterate over the result.\n\n\n\n"
},

{
    "location": "reference.html#Contour.contours",
    "page": "Reference",
    "title": "Contour.contours",
    "category": "Function",
    "text": "contours returns a set of isolines.\n\nYou'll usually call levels on the output of contours.\n\n\n\ncontours(x,y,z,levels) Trace the contour levels indicated by the levels argument.\n\n\n\ncontours(x,y,z,Nlevels::Integer) Trace Nlevels contour levels at heights chosen by the library (using the  contourlevels function).\n\n\n\ncontours(x,y,z) Trace 10 automatically chosen contour levels.\n\n\n\n"
},

{
    "location": "reference.html#Entry-points-1",
    "page": "Reference",
    "title": "Entry points",
    "category": "section",
    "text": "contour\ncontours"
},

{
    "location": "reference.html#Contour.level",
    "page": "Reference",
    "title": "Contour.level",
    "category": "Function",
    "text": "level(c) Indicates the z-value at which the contour level c was traced.\n\n\n\n"
},

{
    "location": "reference.html#Contour.levels",
    "page": "Reference",
    "title": "Contour.levels",
    "category": "Function",
    "text": "Turns the output of contours into an iterable with each of the traced contour levels. Each of the objects support level and coordinates.\n\n\n\n"
},

{
    "location": "reference.html#Contour.lines",
    "page": "Reference",
    "title": "Contour.lines",
    "category": "Function",
    "text": "lines(c) Extracts an iterable collection of isolines from a contour level. Use coordinates to get the coordinates of a line.\n\n\n\n"
},

{
    "location": "reference.html#Contour.coordinates",
    "page": "Reference",
    "title": "Contour.coordinates",
    "category": "Function",
    "text": "coordinates(c) Returns the coordinates of the vertices of the contour line as a tuple of lists.\n\n\n\n"
},

{
    "location": "reference.html#Accessors-1",
    "page": "Reference",
    "title": "Accessors",
    "category": "section",
    "text": "level\nlevels\nlines\ncoordinates"
},

{
    "location": "reference.html#Contour.contourlevels",
    "page": "Reference",
    "title": "Contour.contourlevels",
    "category": "Function",
    "text": "contourlevels(z,n) Examines the values of z and chooses n evenly spaced levels to trace.\n\n\n\n"
},

{
    "location": "reference.html#Utilities-1",
    "page": "Reference",
    "title": "Utilities",
    "category": "section",
    "text": "Contour.contourlevels"
},

]}
