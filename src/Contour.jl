module Contour

using StaticArrays

include("interpolate.jl")

export
    ContourLevel,
    Curve2,
    contour,
    contours,
    level,
    levels,
    lines,
    coordinates

import Base: push!, length, eltype, show

struct Curve2{T}
    vertices::Vector{SVector{2,T}}
end
Curve2(::Type{T}) where {T} = Curve2(SVector{2,T}[])
show(io::IO, ::MIME"text/plain", c2::Curve2) = write(io, "$(typeof(c2))\n  with $(length(c2.vertices)-1) vertices")
show(io::IO, ::MIME"text/plain", c2s::Vector{TC}) where {TC <: Curve2} = write(io, "$(typeof(c2s))\n  $(length(c2s)) contour line(s)")

struct ContourLevel{T}
    level::T
    lines::Vector{Curve2{T}}
end
ContourLevel(h::T) where {T <: AbstractFloat} = ContourLevel(h, Curve2{T}[])
ContourLevel(h::T) where {T} = ContourLevel(Float64(h))
show(io::IO, ::MIME"text/plain", cl::ContourLevel) = write(io, "$(typeof(cl))\n  at $(level(cl)) with $(length(lines(cl))) line(s)")
show(io::IO, ::MIME"text/plain", cls::Vector{CL}) where {CL <: ContourLevel} = write(io, "$(typeof(cls))\n  $(length(cls)) contour level(s)")
"""
`lines(c)` Extracts an iterable collection of isolines from a contour level.
Use [`coordinates`](@ref) to get the coordinates of a line.
"""
lines(cl::ContourLevel) = cl.lines
"""
`level(c)` Indicates the `z`-value at which the contour level `c` was traced.
"""
level(cl::ContourLevel) = cl.level

struct ContourCollection{Tlevel<:ContourLevel}
    contours::Vector{Tlevel}
end
ContourCollection() = ContourCollection(Float64)
ContourCollection(::Type{Tlevel}) where {Tlevel} = ContourCollection(ContourLevel{Tlevel}[])
show(io::IO, ::MIME"text/plain", cc::ContourCollection) = write(io, "$(typeof(cc))\n with $(length(levels(cc))) level(s).")

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
function contour(x, y, z, level::Number, cells = Dict{Tuple{Int,Int},UInt8}())
    # Todo: size checking on x,y,z
    trace_contour(x, y, z, level, get_level_cells(z, level, cells))
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
function contours(x, y, z, levels)
    # reuse lookup dictionary as it is run multiple times and empty after each run
    cells = Dict{Tuple{Int,Int},UInt8}()
    ContourCollection([contour(x, y, z, l, cells) for l in levels])
end

"""
`contours(x,y,z,Nlevels::Integer)` Trace `Nlevels` contour levels at heights
chosen by the library (using the  [`contourlevels`](@ref) function).
"""
function contours(x, y, z, Nlevels::Integer)
    contours(x, y, z, contourlevels(z, Nlevels))
end

"""
`contours(x,y,z)` Trace 10 automatically chosen contour levels.
"""
contours(x, y, z) = contours(x, y, z, 10)

"""
`contourlevels(z,n)` Examines the values of `z` and chooses `n` evenly spaced
levels to trace.
"""
function contourlevels(z, n)
    zmin, zmax = extrema(z)
    dz = (zmax - zmin) / (n + 1)
    range(zmin + dz; step = dz, length = n)
end

"""
`coordinates(c)` Returns the coordinates of the vertices of the contour line as
a tuple of lists.
"""
function coordinates(c::Curve2{T}) where {T}
    N = length(c.vertices)
    xlist = Vector{T}(undef, N)
    ylist = Vector{T}(undef, N)

    for (i, v) in enumerate(c.vertices)
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
const N, S, E, W = (UInt8(1)), (UInt8(2)), (UInt8(4)), (UInt8(8))
const NS, NE, NW = N|S, N|E, N|W
const SN, SE, SW = S|N, S|E, S|W
const EN, ES, EW = E|N, E|S, E|W
const WN, WS, WE = W|N, W|S, W|E
const NWSE = NW | 0x10 # special (ambiguous case)
const NESW = NE | 0x10 # special (ambiguous case)

# Maps cell type to crossing types for non-ambiguous cells
const edge_LUT = (SW, SE, EW, NE, 0x0, NS, NW, NW, NS, 0x0, NE, EW, SE, SW)

# The way a contour crossing goes through a cell is labeled
# by combining compass directions (e.g. a NW crossing connects
# the N edge and W edges of the cell).  The Cell type records
# the type of crossing that a cell contains.  While most
# cells will have only one crossing, cell type 5 and 10 will
# have two crossings.
function get_next_edge!(cells::Dict, xi, yi, entry_edge::UInt8)
    key = (xi,yi)
    cell = cells[key]
    if cell == NWSE
        if !iszero(NW & entry_edge)
            cells[key] = SE
            return NW ⊻ entry_edge
        else #Nw
            cells[key] = NW
            return SE ⊻ entry_edge
        end
    elseif cell == NESW
        if !iszero(NE & entry_edge)
            cells[key] = SW
            return NE ⊻ entry_edge
        else #SW
            cells[key] = NE
            return SW ⊻ entry_edge
        end
    else
        next_edge = cell ⊻ entry_edge
        delete!(cells, key)
        return next_edge
    end
end

@inline function advance_edge(xi::T,yi::T,edge) where T
    if edge == N
        return xi, yi+one(T), S
    elseif edge == S
        return xi, yi-one(T), N
    elseif edge == E
        return xi+one(T), yi, W
    elseif edge == W
        return xi-one(T), yi, E
    end
end

@inline function get_first_crossing(cell)
    if cell == NWSE
        return NW
    elseif cell == NESW
        return NE
    else
        return cell
    end
end

@inline function _get_case(z, h)
    case = z[1] > h ? 0x01 : 0x00
    z[2] > h && (case |= 0x02)
    z[3] > h && (case |= 0x04)
    z[4] > h && (case |= 0x08)
    case
end

function get_level_cells(z, h::Number, cells = Dict{Tuple{Int,Int},UInt8}())

    xi_max, yi_max = size(z)

    @inbounds for xi in 1:xi_max - 1
        for yi in 1:yi_max - 1
            elts = (z[xi, yi], z[xi + 1, yi], z[xi + 1, yi + 1], z[xi, yi + 1])
            case = _get_case(elts, h)

            # Contour does not go through these cells
            if iszero(case) || case == 0x0f
                continue
            end

            # Process ambiguous cells (case 5 and 10) using
            # a bilinear interpolation of the cell-center value.
            if case == 0x05
                cells[(xi, yi)] = 0.25*sum(elts) >= h ? NWSE : NESW
            elseif case == 0x0a
                cells[(xi, yi)] = 0.25*sum(elts) >= h ? NESW : NWSE
            else
                cells[(xi, yi)] = edge_LUT[case]
            end
        end
    end

    return cells
end


# Given a cell and a starting edge, we follow the contour line until we either
# hit the boundary of the input data, or we form a closed contour.
function chase!(cells, curve, x, y, z, h, xi_start, yi_start, entry_edge, xi_max, yi_max, ::Type{VT}) where VT

    xi, yi = xi_start, yi_start

    # When the contour loops back to the starting cell, it is possible
    # for it to not intersect with itself.  This happens if the starting
    # cell contains a saddle-point. So a loop is only closed if the
    # contour returns to the starting edge of the starting cell
    loopback_edge = entry_edge

    @inbounds while true
        exit_edge = get_next_edge!(cells, xi, yi, entry_edge)

        push!(curve, interpolate(x, y, z, h, xi, yi, exit_edge, VT))

        xi, yi, entry_edge = advance_edge(xi, yi, exit_edge)

        !((xi, yi, entry_edge) != (xi_start, yi_start, loopback_edge) &&
           0 < yi < yi_max && 0 < xi < xi_max) && break
    end

    return xi, yi
end


function trace_contour(x, y, z, h::Number, cells::Dict)

    contours = ContourLevel(h)

    (xi_max, yi_max) = size(z)::Tuple{Int,Int}

    VT = SVector{2,promote_type(map(eltype, (x, y, z))...)}

    # When tracing out contours, this algorithm picks an arbitrary
    # starting cell, then first follows the contour in one direction
    # until it either ends up where it started # or at one of the boundaries.
    # It then tries to trace the contour in the opposite direction.

    @inbounds while length(cells) > 0
        contour_arr = VT[]

        # Pick initial box
        (xi, yi), cell = first(cells)

        # Pick a starting edge
        crossing = get_first_crossing(cell)
        starting_edge = UInt8(0)
        for edge in (N, S, E, W)
            if !iszero(edge & crossing)
                starting_edge = edge
                break
            end
        end

        # Add the contour entry location for cell (xi_0,yi_0)
        push!(contour_arr, interpolate(x, y, z, h, xi, yi, starting_edge, VT))

        # Start trace in forward direction
        xi_end, yi_end = chase!(cells, contour_arr, x, y, z, h, xi, yi, starting_edge, xi_max, yi_max, VT)

        if xi_end == xi && yi_end == yi
            push!(contours.lines, Curve2(contour_arr))
            continue
        end

        xi, yi, starting_edge = advance_edge(xi, yi, starting_edge)

        if 0 < yi < yi_max && 0 < xi < xi_max
            # Start trace in reverse direction
            chase!(cells, reverse!(contour_arr), x, y, z, h, xi, yi, starting_edge, xi_max, yi_max, VT)
        end

        push!(contours.lines, Curve2(contour_arr))
    end

    return contours

end

end
