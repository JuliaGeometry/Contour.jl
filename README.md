# Contour

[![Build Status](https://travis-ci.org/tlycken/Contour.jl.svg?branch=master)](https://travis-ci.org/tlycken/Contour.jl)
[![Coverage Status](https://img.shields.io/coveralls/tlycken/Contour.jl.svg?branch=master)](https://coveralls.io/r/tlycken/Contour.jl)

A generic library for tracing contour curves on a scalar 2D field, mainly authored by Darwin Darakananda ([**@darwindarak**](https://github.com/darwindarak/)).

The idea with this library is to separate the contouring alghorithm(s) from the various visualization tools, so that all tools can benefit from advances made here - as well as in other applications, independenly of choice of visualization tool. The current implementation use the [marching squares algorithm](http://en.wikipedia.org/wiki/Marching_squares) to calculate contours.

There are [ongoing](https://github.com/tlycken/Contour.jl/issues/1) [api-discussions](https://github.com/tlycken/Contour.jl/issues/2), so the API of this library should not be considered stable yet. As a consequence, it is not yet published to METADATA, but can still be downloaded through `Pkg.clone("https://github.com/tlycken/Contour.jl.git")` if you want to kick the tires or help out. Hopefully, [this discussion on the users list](https://groups.google.com/forum/?fromgroups=#!topic/julia-dev/fqwnyOojRdg) concerning a generic package for geometric objects like points and lines will yield something useful, in which case this package will be adjusted to use those types.
