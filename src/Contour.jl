module Contour

using StaticArrays

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
function contour(x, y, z, level::Number)
    # Todo: size checking on x,y,z
    cells, cell_pop = get_level_cells(z, level)
    trace_contour(x, y, z, level, cells, cell_pop)
end

function contour(cells, x, y, z, level::Number)
    # Todo: size checking on x,y,z
    cell_pop = get_level_cells!(cells, z, level)
    trace_contour(x, y, z, level, cells, cell_pop)
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
    cells = cell_matrix(z)
    ContourCollection([contour(cells, x, y, z, l) for l in levels])
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

const dirStr = ["N", "S", "NS", "E", "NE", "NS", "Invalid crossing",
                "W", "NW", "SW", "Invalid crossing", "WE"]

# The way a contour crossing goes through a cell is labeled
# by combining compass directions (e.g. a NW crossing connects
# the N edge and W edges of the cell).  The Cell type records
# the type of crossing that a cell contains.  While most
# cells will have only one crossing, cell type 5 and 10 will
# have two crossings.
function get_next_edge!(cells::Array, xi, yi, entry_edge::UInt8, cell_pop)
    cell = cells[xi,yi]
    if cell != NWSE && cell != NESW
        next_edge = cell ⊻ entry_edge
        cells[xi,yi] = 0x0
        return next_edge, cell_pop - 1
    else  # ambiguous case flag
        if cell == NWSE
            if !iszero(NW & entry_edge)
                cells[xi,yi] = SE
                return NW ⊻ entry_edge, cell_pop
            elseif !iszero(SE & entry_edge)
                cells[xi,yi] = NW
                return SE ⊻ entry_edge, cell_pop
            end
        elseif cell == NESW
            if !iszero(NE & entry_edge)
                cells[xi,yi] = SW
                return NE ⊻ entry_edge, cell_pop
            elseif !iszero(SW & entry_edge)
                cells[xi,yi] = NE
                return SW ⊻ entry_edge, cell_pop
            end
        end
    end
end

function get_first_crossing(cell)
    cell & 0x0f
end

# Maps cell type to crossing types for non-ambiguous cells
const edge_LUT = (SW, SE, EW, NE, 0x0, NS, NW, NW, NS, 0x0, NE, EW, SE, SW)

function _get_case(z, h)
    @inbounds begin
        case = z[1] > h ? 0x01 : 0x00
        z[2] > h && (case |= 0x02)
        z[3] > h && (case |= 0x04)
        z[4] > h && (case |= 0x08)
        case
    end
end

function cell_matrix(z)
    xi_max, yi_max = size(z)
    cells = zeros(UInt8, (xi_max-1,yi_max-1))
end

function get_level_cells(z,h::Number)
    cells = cell_matrix(z)
    cell_pop = get_level_cells!(cells, z, h)
    cells, cell_pop
end

function get_level_cells!(cells, z, h::Number)
    xi_max, yi_max = size(z)

    cell_pop = 0

    @inbounds for yi in 1:yi_max - 1
        for xi in 1:xi_max - 1
            elts = (z[xi, yi], z[xi + 1, yi], z[xi + 1, yi + 1], z[xi, yi + 1])
            case = _get_case(elts, h)

            # Contour does not go through these cells
            if iszero(case) || case == 0x0f
                continue
            end

            cell_pop += 1 # number of cells in the array populated

            # Process ambiguous cells (case 5 and 10) using
            # a bilinear interpolation of the cell-center value.
            if case == 0x05
                if 0.25*sum(elts) >= h
                    cells[xi, yi] = NWSE
                else
                    cells[xi, yi] = NESW
                end
            elseif case == 0x0a
                if 0.25*sum(elts) >= h
                    cells[xi, yi] = NESW
                else
                    cells[xi, yi] = NWSE
                end
            else
                cells[xi, yi] = edge_LUT[case]
            end
        end
    end

    return cell_pop
end

function findfirst_cell(m, from_x, from_y)
    s = size(m)::Tuple{Int,Int}
    @inbounds for xi = from_x:s[1], yi = from_y:s[2]
        !iszero(m[xi,yi]) && return xi,yi
    end
    return 0,0
end

# Some constants used by trace_contour

const fwd, rev = (UInt8(0)), (UInt8(1))

function add_vertex!(curve::Curve2{T}, pos::Tuple{T,T}, dir::UInt8) where {T}
    if dir == fwd
        push!(curve.vertices, SVector{2,T}(pos...))
    else
        pushfirst!(curve.vertices, SVector{2,T}(pos...))
    end
end

# Given the row and column indices of the lower left
# vertex, add the location where the contour level
# crosses the specified edge.
function interpolate(x::AbstractVector{T}, y::AbstractVector{T}, z::AbstractMatrix{T}, h::Number, xi::Int, yi::Int, edge::UInt8) where {T <: AbstractFloat}
    if edge == W
        @inbounds y_interp = y[yi] + (y[yi + 1] - y[yi]) * (h - z[xi, yi]) / (z[xi, yi + 1] - z[xi, yi])
        @inbounds x_interp = x[xi]
    elseif edge == E
        @inbounds y_interp = y[yi] + (y[yi + 1] - y[yi]) * (h - z[xi + 1, yi]) / (z[xi + 1, yi + 1] - z[xi + 1, yi])
        @inbounds x_interp = x[xi + 1]
    elseif edge == N
        @inbounds y_interp = y[yi + 1]
        @inbounds x_interp = x[xi] + (x[xi + 1] - x[xi]) * (h - z[xi, yi + 1]) / (z[xi + 1, yi + 1] - z[xi, yi + 1])
    elseif edge == S
        @inbounds y_interp = y[yi]
        @inbounds x_interp = x[xi] + (x[xi + 1] - x[xi]) * (h - z[xi, yi]) / (z[xi + 1, yi] - z[xi, yi])
    end

    return x_interp, y_interp
end

function interpolate(x::AbstractMatrix{T}, y::AbstractMatrix{T}, z::AbstractMatrix{T}, h::Number, xi::Int, yi::Int, edge::UInt8) where {T <: AbstractFloat}
    if edge == W
        Δ = [y[xi,  yi+1] - y[xi,  yi  ], x[xi,  yi+1] - x[xi,  yi  ]].*(h - z[xi,  yi  ])/(z[xi,  yi+1] - z[xi,  yi  ])
        y_interp = y[xi,yi] + Δ[1]
        x_interp = x[xi,yi] + Δ[2]
    elseif edge == E
        Δ = [y[xi+1,yi+1] - y[xi+1,yi  ], x[xi+1,yi+1] - x[xi+1,yi  ]].*(h - z[xi+1,yi  ])/(z[xi+1,yi+1] - z[xi+1,yi  ])
        y_interp = y[xi+1,yi] + Δ[1]
        x_interp = x[xi+1,yi] + Δ[2]
    elseif edge == N
        Δ = [y[xi+1,yi+1] - y[xi,  yi+1], x[xi+1,yi+1] - x[xi,  yi+1]].*(h - z[xi,  yi+1])/(z[xi+1,yi+1] - z[xi,  yi+1])
        y_interp = y[xi,yi+1] + Δ[1]
        x_interp = x[xi,yi+1] + Δ[2]
    elseif edge == S
        Δ = [y[xi+1,yi  ] - y[xi,  yi  ], x[xi+1,yi  ] - x[xi,  yi  ]].*(h - z[xi,  yi  ])/(z[xi+1,yi  ] - z[xi,  yi  ])
        y_interp = y[xi,yi] + Δ[1]
        x_interp = x[xi,yi] + Δ[2]
    end

    return x_interp, y_interp
end


# Given a cell and a starting edge, we follow the contour line until we either
# hit the boundary of the input data, or we form a closed contour.
function chase!(cells, curve, x, y, z, h, xi_start, yi_start, entry_edge, xi_max, yi_max, cell_pop, dir)

    xi, yi = xi_start, yi_start

    # When the contour loops back to the starting cell, it is possible
    # for it to not intersect with itself.  This happens if the starting
    # cell contains a saddle-point. So a loop is only closed if the
    # contour returns to the starting edge of the starting cell
    loopback_edge = entry_edge

    while true
        exit_edge, cell_pop = get_next_edge!(cells, xi, yi, entry_edge, cell_pop)

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
        !((xi, yi, entry_edge) != (xi_start, yi_start, loopback_edge) &&
           0 < yi < yi_max && 0 < xi < xi_max) && break
    end

    return xi, yi, cell_pop
end


function trace_contour(x, y, z, h::Number, cells::Array, cell_pop)

    contours = ContourLevel(h)

    (xi_max, yi_max) = size(z)

    # When tracing out contours, this algorithm picks an arbitrary
    # starting cell, then first follows the contour in one direction
    # until it either ends up where it started # or at one of the boundaries.
    # It then tries to trace the contour in the opposite direction.

    nonempty_cells = cell_pop
    (xi_0, yi_0) = (1,1)

    @inbounds while nonempty_cells > 0
        contour = Curve2(promote_type(map(eltype, (x, y, z))...))

        # Pick initial box
        (xi_0, yi_0) = findfirst_cell(cells, xi_0, yi_0)
        iszero(xi_0) && iszero(yi_0) && break
        (xi, yi) = (xi_0, yi_0)
        cell = cells[xi,yi]

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
        add_vertex!(contour, interpolate(x, y, z, h, xi_0, yi_0, starting_edge), fwd)

        # Start trace in forward direction
        xi_end, yi_end, cp = chase!(cells, contour, x, y, z, h, xi, yi, starting_edge, xi_max, yi_max, nonempty_cells, fwd)
        nonempty_cells = cp

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
        xi, yi, cp = chase!(cells, contour, x, y, z, h, xi, yi, starting_edge, xi_max, yi_max, nonempty_cells, rev)
        nonempty_cells = cp
        push!(contours.lines, contour)
    end

    return contours

end

end
