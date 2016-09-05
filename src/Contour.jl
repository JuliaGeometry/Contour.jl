module Contour

using Compat, FixedSizeArrays

export  
    ContourLevel,
    Curve2,
    contour,
    contours,
    level,
    levels,
    lines,
    coordinates

@compat import Base: push!, start, next, done, length, eltype, show

type Curve2{T}
    vertices::Vector{Point{2,T}}
end
Curve2{T}(::Type{T}) = Curve2(Point{2, T}[])
@compat show(io::IO, ::MIME"text/plain", c2::Curve2) = write(io, "$(typeof(c2))\n  with $(length(c2.vertices)-1) vertices")
@compat show{TC<:Curve2}(io::IO, ::MIME"text/plain", c2s::Vector{TC}) = write(io, "$(typeof(c2s))\n  $(length(c2s)) contour line(s)")

type ContourLevel{T}
    level::T
    lines::Vector{Curve2{T}}
end
ContourLevel{T<:AbstractFloat}(h::T) = ContourLevel(h, Curve2{T}[])
ContourLevel{T}(h::T) = ContourLevel(Float64(h))
@compat show(io::IO, ::MIME"text/plain", cl::ContourLevel) = write(io, "$(typeof(cl))\n  at $(level(cl)) with $(length(lines(cl))) line(s)")
@compat show{CL<:ContourLevel}(io::IO, ::MIME"text/plain", cls::Vector{CL}) = write(io, "$(typeof(cls))\n  $(length(cls)) contour level(s)")
"""
`lines(c)` Extracts an iterable collection of isolines from a contour level.
Use [`coordinates`](@ref) to get the coordinates of a line.
"""
lines(cl::ContourLevel) = cl.lines
"""
`level(c)` Indicates the `z`-value at which the contour level `c` was traced.
"""
level(cl::ContourLevel) = cl.level

immutable ContourCollection{Tlevel<:ContourLevel}
    contours::Vector{Tlevel}
end
ContourCollection() = ContourCollection(Float64)
ContourCollection{Tlevel}(::Type{Tlevel}) = ContourCollection(ContourLevel{Tlevel}[])
@compat show(io::IO, ::MIME"text/plain", cc::ContourCollection) = write(io, "$(typeof(cc))\n with $(length(levels(cc))) level(s).")

"""
Turns the output of [`contours`](@ref) into an iterable with each of the traced
contour levels. Each of the objects support [`level`](@ref) and
[`coordinates`](@ref).
"""
levels(cc::ContourCollection) = cc.contours

"""
`contour(x, y, z, level::Number)` Trace a single contour level, indicated by the
argument `level`.

You'll usually call [`lines`](@ref) on the output of `contour`, and then iterate
over the result.
"""
function contour(x, y, z, level::Number)
    # Todo: size checking on x,y,z
    trace_contour(x, y, z,level,get_level_cells(z,level))
end

"""
`contours` returns a set of isolines.

You'll usually call [`levels`](@ref) on the output of `contours`.
"""
contours(::Any...) = error("This method exists only for documentation purposes")

"""
`contours(x,y,z,levels)` Trace the contour levels indicated by the `levels`
argument.
"""
contours(x,y,z,levels) = ContourCollection([contour(x,y,z,l) for l in levels])

"""
`contours(x,y,z,Nlevels::Integer)` Trace `Nlevels` contour levels at heights
chosen by the library (using the  [`contourlevels`](@ref) function).
"""
function contours(x,y,z,Nlevels::Integer)
    contours(x,y,z,contourlevels(z,Nlevels))
end

"""
`contours(x,y,z)` Trace 10 automatically chosen contour levels.
"""
contours(x,y,z) = contours(x,y,z,10)

"""
`contourlevels(z,n)` Examines the values of `z` and chooses `n` evenly spaced
levels to trace.
"""
function contourlevels(z,n)
    zmin,zmax = extrema(z)
    dz = (zmax-zmin) / (n+1)
    range(zmin+dz,dz,n)
end

"""
`coordinates(c)` Returns the coordinates of the vertices of the contour line as
a tuple of lists.
"""
function coordinates{T}(c::Curve2{T})
    N = length(c.vertices)
    xlist = Array(T,N)
    ylist = Array(T,N)

    for (i,v) in enumerate(c.vertices)
        xlist[i] = v[1]
        ylist[i] = v[2]
    end
    xlist, ylist
end

# The marching squares algorithm defines 16 cell types
# based on the edges that a contour line enters and exits
# through. The edges of the cells are identified using
# compass directions, while the vertices are ordered as
# follows:
#
#      N
#  4 +---+ 3
# W  |   |  E
#  1 +---+ 2
#      S
#
# Each cell type is identified with 4 bits, with each
# bit corresponding to a vertex (MSB -> 4, LSB -> 1).
# A bit is set for vertex v_i is set if z(v_i) > h. So a cell
# where a contour line only enters from the W edge and exits
# through the N edge will have the cell type: 0b0111
# Note that there are two cases where there are two
# lines crossing through the same cell: 0b0101, 0b1010.
const N, S, E, W = (@compat UInt8(1)), (@compat UInt8(2)), (@compat UInt8(4)), (@compat UInt8(8))
const NS, NE, NW = N|S, N|E, N|W
const SN, SE, SW = S|N, S|E, S|W
const EN, ES, EW = E|N, E|S, E|W
const WN, WS, WE = W|N, W|S, W|E

const dirStr = ["N", "S", "NS", "E", "NE", "NS", "Invalid crossing", 
                "W", "NW", "SW", "Invalid crossing", "WE"]

# The way a contour crossing goes through a cell is labeled
# by combining compass directions (e.g. a NW crossing connects
# the N edge and W edges of the cell).  The Cell type records
# the type of crossing that a cell contains.  While most
# cells will have only one crossing, cell type 5 and 10 will
# have two crossings.
type Cell
    crossings::Vector{UInt8}
end

function get_next_edge!(cell::Cell, entry_edge::UInt8)
    for (i,edge) in enumerate(cell.crossings)
        if edge & entry_edge != 0
            next_edge = edge $ entry_edge
            deleteat!(cell.crossings, i)

            return next_edge
        end
    end
    error("There is no edge containing ", entry_edge)
end

# Maps cell type to crossing types for non-ambiguous cells
const edge_LUT = [SW, SE, EW, NE, 0, NS, NW, NW, NS, 0, NE, EW, SE, SW]

function get_level_cells(z, h::Number)
    cells = Dict{(@compat Tuple{Int,Int}),Cell}()
    xi_max, yi_max = size(z)

    local case::Int8

    for xi in 1:xi_max-1
        for yi in 1:yi_max-1
            case = 1(z[xi,yi] > h)     |
                   2(z[xi+1,yi] > h)   |
                   4(z[xi+1,yi+1] > h) |
                   8(z[xi,yi+1] > h)

            # Contour does not go through these cells
            if case == 0 || case == 15
                continue
            end

            # Process ambiguous cells (case 5 and 10) using
            # a bilinear interpolation of the cell-center value.
            if case == 5
                if 0.25(z[xi,yi] + z[xi,yi+1] + z[xi+1,yi] + z[xi+1,yi+1]) >= h
                    cells[(xi,yi)] = Cell([NW, SE])
                else
                    cells[(xi,yi)] = Cell([NE, SW])
                end
            elseif case == 10
                if 0.25(z[xi,yi] + z[xi,yi+1] + z[xi+1,yi] + z[xi+1,yi+1]) >= h
                    cells[(xi,yi)] = Cell([NE, SW])
                else
                    cells[(xi,yi)] = Cell([NW, SE])
                end
            else
                cells[(xi,yi)] = Cell([edge_LUT[case]])
            end
        end
    end

    return cells
end

# Some constants used by trace_contour

const fwd, rev = (@compat UInt8(0)), (@compat UInt8(1))

function add_vertex!{T}(curve::Curve2{T}, pos::(@compat Tuple{T,T}), dir::UInt8)
    if dir == fwd
        push!(curve.vertices, Point{2,T}(pos...))
    else
        unshift!(curve.vertices, Point{2,T}(pos...))
    end
end

# Given the row and column indices of the lower left
# vertex, add the location where the contour level
# crosses the specified edge.
function interpolate{T<:AbstractFloat}(x, y, z::Matrix{T}, h::Number, xi::Int, yi::Int, edge::UInt8)
    if edge == W
        y_interp = y[yi] + (y[yi+1] - y[yi])*(h - z[xi,yi])/(z[xi,yi+1] - z[xi,yi])
        x_interp = x[xi]
    elseif edge == E
        y_interp = y[yi] + (y[yi+1] - y[yi])*(h - z[xi+1,yi])/(z[xi+1,yi+1] - z[xi+1,yi])
        x_interp = x[xi + 1]
    elseif edge == N
        y_interp = y[yi + 1]
        x_interp = x[xi] + (x[xi+1] - x[xi])*(h - z[xi,yi+1])/(z[xi+1,yi+1] - z[xi,yi+1])
    elseif edge == S
        y_interp = y[yi]
        x_interp = x[xi] + (x[xi+1] - x[xi])*(h - z[xi,yi])/(z[xi+1,yi] - z[xi,yi])
    end

    return x_interp, y_interp
end

# Given a cell and a starting edge, we follow the contour line until we either
# hit the boundary of the input data, or we form a closed contour.
function chase!(cells, curve, x, y, z, h, xi_start, yi_start, entry_edge, xi_max, yi_max, dir)

    xi, yi = xi_start, yi_start

    # When the contour loops back to the starting cell, it is possible
    # for it to not intersect with itself.  This happens if the starting
    # cell contains a saddle-point. So a loop is only closed if the 
    # contour returns to the starting edge of the starting cell
    loopback_edge = entry_edge

    while true
        cell = cells[(xi,yi)]
        exit_edge = get_next_edge!(cell, entry_edge)
        if length(cell.crossings) == 0
            delete!(cells, (xi,yi))
        end

        add_vertex!(curve, interpolate(x, y, z, h, xi, yi, exit_edge), dir)

        if exit_edge == N
            yi += 1
            entry_edge = S
        elseif exit_edge == S
            yi -= 1
            entry_edge = N
        elseif exit_edge == E
            xi += 1
            entry_edge = W
        elseif exit_edge == W
            xi -= 1
            entry_edge = E
        end
        !((xi,yi,entry_edge) != (xi_start,yi_start, loopback_edge) && 
           0 < yi < yi_max && 0 < xi < xi_max) && break
    end

    return xi, yi
end


function trace_contour(x, y, z, h::Number, cells::Dict{(@compat Tuple{Int,Int}),Cell})

    contours = ContourLevel(h)

    local yi::Int
    local xi::Int
    local xi_0::Int
    local yi_0::Int

    local xi_max::Int
    local yi_max::Int

    (xi_max, yi_max) = size(z)

    # When tracing out contours, this algorithm picks an arbitrary
    # starting cell, then first follows the contour in one direction
    # until it either ends up where it started # or at one of the boundaries.  
    # It then tries to trace the contour in the opposite direction.

    while length(cells) > 0
        contour = Curve2(promote_type(map(eltype, (x,y,z))...))

        # Pick initial box
        (xi_0, yi_0), cell = first(cells)
        (xi,yi) = (xi_0,yi_0)

        # Pick a starting edge
        crossing = first(cell.crossings)
        starting_edge = @compat UInt8(0)
        for edge in [N, S, E, W]
            if edge & crossing != 0
                starting_edge = edge
                break
            end
        end

        # Add the contour entry location for cell (xi_0,yi_0)
        add_vertex!(contour, interpolate(x, y, z, h, xi_0, yi_0, starting_edge), fwd)

        # Start trace in forward direction
        (xi_end, yi_end) = chase!(cells, contour, x, y, z, h, xi, yi, starting_edge, xi_max, yi_max, fwd)
        
        if (xi_end, yi_end) == (xi_0, yi_0)
            push!(contours.lines, contour)
            continue
        end
        
        if starting_edge == N
            yi = yi_0 + 1
            starting_edge = S
        elseif starting_edge == S
            yi = yi_0 - 1
            starting_edge = N
        elseif starting_edge == E
            xi = xi_0 + 1
            starting_edge = W
        elseif starting_edge == W
            xi = xi_0 - 1
            starting_edge = E
        end
        
        if !(0 < yi < yi_max && 0 < xi < xi_max)
            push!(contours.lines, contour)
            continue
        end
        
        # Start trace in reverse direction
        (xi, yi) = chase!(cells, contour, x, y, z, h, xi, yi, starting_edge, xi_max, yi_max, rev)
        push!(contours.lines, contour)
    end

    return contours

end

end
