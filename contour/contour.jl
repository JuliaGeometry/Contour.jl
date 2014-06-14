module Contour

using Gadfly
using Grid
using Color

type ContourLine
    x::Vector{Float64}
    y::Vector{Float64}
end

export contour_layers

function contour_layers(X::Vector{Float64}, Y::Vector{Float64}, z::Array{Float64,2})
    h = linspace(minimum(z), maximum(z), 30);
    X_c = InterpGrid(X, BCnan, InterpLinear);
    Y_c = InterpGrid(Y, BCnan, InterpLinear);
    colors = colormap("Blues", 30);
    layers = Array(Layer,0)
    for (i,l) in enumerate(h)
        cells = get_level_cells(z, l)
        c = trace_contour(z, l, cells)
        for line in c
            push!(layers, layer(x=X_c[line.x], y=Y_c[line.y], Geom.line(preserve_order=true), Theme(default_color=colors[i])))
        end
    end

    return layers
end

function get_level_cells(z::Array{Float64, 2}, h::Float64)
    cells = Dict{(Int64,Int64),Int8}()
    r_max, c_max = size(z)
    for c in 1:c_max-1
        for r in 1:r_max-1
            case::Int8
            case = 1(z[r,c] > h) + 8(z[r+1,c] > h) + 2(z[r,c+1] > h) + 4(z[r+1,c+1] > h)
            if case != 0 && case != 15
                if case == 5
                    cells[(r,c)] = 16 + (0.25(z[r, c] + z[r+1, c] + z[r, c+1] + z[r+1, c+1]) > h)
                elseif case == 10
                    cells[(r,c)] = 18 + (0.25(z[r,c] + z[r+1,c] + z[r,c+1] + z[r+1, c+1]) > h)
                else
                    cells[(r,c)] = case
                end
            end
        end
    end

    return cells
end

function trace_contour(z::Array{Float64,2},
                       h::Float64,
                       cells::Dict{(Int64,Int64),Int8})

    contours = Array(ContourLine, 0)

    local r::Int64
    local c::Int64

    local r_max::Int64
    local c_max::Int64

    (r_max, c_max) = size(z)

    while length(cells) > 0
        r0::Int64
        c0::Int64
        case::Int8
        case0::Int8

        contour = ContourLine(Array(Float64,0), Array(Float64,0))

        # This is a complete hack at the moment.
        # Have to replace this section!!!

        function lt(row::Int64, col::Int64, front::Bool = false)
            if (!front)
                push!(contour.x, col)
                push!(contour.y, row + (h - z[row,col])/(z[row+1,col] - z[row,col]))
            else
                unshift!(contour.x, col)
                unshift!(contour.y, row + (h - z[row,col])/(z[row+1,col] - z[row,col]))
            end
        end

        function rt(row::Int64, col::Int64, front::Bool = false)
            if (!front)
                push!(contour.x, col + 1)
                push!(contour.y, row + (h - z[row,col+1])/(z[row+1,col+1] - z[row,col+1]))
            else
                unshift!(contour.x, col + 1)
                unshift!(contour.y, row + (h - z[row,col+1])/(z[row+1,col+1] - z[row,col+1]))
            end
        end

        function up(row::Int64, col::Int64, front::Bool = false)
            if (!front)
                push!(contour.x, col + (h - z[row+1,col])/(z[row+1,col+1] - z[row+1,col]))
                push!(contour.y, row + 1)
            else
                unshift!(contour.x, col + (h - z[row+1,col])/(z[row+1,col+1] - z[row+1,col]))
                unshift!(contour.y, row + 1)
            end
        end

        function dn(row::Int64, col::Int64, front::Bool = false)
            if (!front)
                push!(contour.x, col + (h - z[row,col])/(z[row,col+1] - z[row,col]))
                push!(contour.y, row)
            else
                unshift!(contour.x, col + (h - z[row,col])/(z[row,col+1] - z[row,col]))
                unshift!(contour.y, row)
            end
        end

        # cols       1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16  17  18  19
         cwdir_r = [+0, -1, +0, +0, +0, -1, +0, +1, +1, +0, +1, +0, +0, -1, +0, +0, +0, +1, -1]
         cwdir_c = [-1, +0, -1, +1, +0, +0, -1, +0, +0, +0, +0, +1, +1, +0, +0, -1, -1, +0, +0]

        ccwdir_r = [-1, +0, +0, +1, +0, +1, +1, +0, -1, +0, +0, +0, -1, +0, +0, -1, +1, +0, +0]
        ccwdir_c = [+0, +1, +1, +0, +0, +0, +0, -1, +0, +0, +1, -1, +0, -1, +0, +0, +0, -1, -1]

         cwdir_f = [lt, dn, lt, rt, rt, dn, lt, up, up, up, up, rt, rt, dn, dn, lt, lt, up, dn]
        ccwdir_f = [dn, rt, rt, up, up, up, up, lt, dn, dn, rt, lt, dn, lt, lt, dn, up, dn, lt]
        # Pick initial box
        (r0, c0), case0 = first(cells)
        (r,c) = (r0,c0)
        case = case0

        # Start trace in CCW direction
        # Add starting point
        cwdir_f[case](r0, c0)
        (r,c) = (r0 + ccwdir_r[case], c0 + ccwdir_c[case])
        if case < 15
            delete!(cells, (r0,c0))
        end

        # Trace line until we end up where we started, or we hit the boundary
        while (r,c) != (r0,c0) && r != r_max && c != c_max && r > 0 && c > 0
            case = cells[(r,c)]
            ccwdir_f[case](r,c)
            if case == 16
                cells[(r,c)] = 4
            elseif case == 17
                cells[(r,c)] = 13
            elseif case == 18
                cells[(r,c)] = 2
            elseif case == 19
                cells[(r,c)] = 11
            else
                delete!(cells, (r,c))
            end
            (r,c) = (r + ccwdir_r[case], c + ccwdir_c[case])
        end

        # If we hit the boundary, work backwards
        if (r,c) != (r0,c0)
            (r,c) = (r0 + cwdir_r[case0], c0 + cwdir_c[case0])
        end

        while (r,c) != (r0,c0) && r != r_max && c != c_max && r > 0 && c > 0
            case = cells[(r,c)]
            cwdir_f[case](r,c, true)
            if case == 16
                cells[(r,c)] = 4
            elseif case == 17
                cells[(r,c)] = 13
            elseif case == 18
                cells[(r,c)] = 2
            elseif case == 19
                cells[(r,c)] = 11
            else
                delete!(cells, (r,c))
            end
            (r,c) = (r + cwdir_r[case], c + cwdir_c[case])
        end
        push!(contours, contour)
    end

    return contours

end

end
