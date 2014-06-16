module Contour

using Grid

type ContourLine
    x::Vector{Float64}
    y::Vector{Float64}
end
ContourLine() = ContourLine(Array(Float64,0), Array(Float64,0))

export ContourLine, contour_layers, contours

function contours(x, y, z, level::Number)
    # Todo: size checking on x,y,z
    trace_contour(z,level,get_level_cells(z,level))
end
contours(x,y,z,levels) = [contours(x,y,z,l) for l in levels]

# Look for marching-square cells given data on a cartesian grid
function get_level_cells(z, h::Number)
    cells = Dict{(Int,Int),Int8}()
    r_max, c_max = size(z)
    
    # Identify the type of contour crossing by going
    # through the four vertices of the cell. We append
    # a 1 bit when we enconter a vertex that has a higher
    # value than the contourl level, and a 0 bit otherwise.

    # 4 +---+ 3             8 +---+ 4
    #   |   |       ->        |   |
    # 1 +---+ 2             1 +---+ 2
    
    for c in 1:c_max-1
        for r in 1:r_max-1
            case::Int8
            case = 1(z[r,c] > h)     | 
                   2(z[r,c+1] > h)   | 
                   4(z[r+1,c+1] > h) |
                   8(z[r+1,c] > h)
                   
            # Process ambigous cells (case 5 and 10) using 
            # a bilinear interplotation of the cell-center value.  
            # We add cases 16-19 to handle these cells
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

function trace_contour(z, h::Number, cells::Dict{(Int,Int),Int8})
    contours = Array(ContourLine, 0)

    local r::Int
    local c::Int
    local r0::Int
    local c0::Int

    local r_max::Int
    local c_max::Int

    (r_max, c_max) = size(z)
    
    # When tracing out contours, this algorithm picks an arbitrary
    # starting cell, then first follows the contour in the conouter
    # clockwise direction until it either ends up where it started
    # or at one of the boundaries.  It then tries to trace the contour
    # in the opposite direction.
    
    const lt::Int8,rt::Int8,up::Int8,dn::Int8 = 1,2,3,4
    const ccw::Int8, cw::Int8 = 1, 2
    
    # Each row in the constants refer to a marching squares case,
    # while each column correspond to a search direction.
    # The exit_face LUT finds the edge where the contour leaves
    # The dir_r/c constants points to the location of the next cell.

    const dir_r = int8(
        [-1 +0 +0 +1 +0 +1 +1 +0 -1 +0 +0 +0 -1 +0 +0 -1 +1 +0 +0;
         +0 -1 +0 +0 +0 -1 +0 +1 +1 +0 +1 +0 +0 -1 +0 +0 +0 +1 -1]')
    const dir_c = int8(
        [+0 +1 +1 +0 +0 +0 +0 -1 +0 +0 +1 -1 +0 -1 +0 +0 +0 -1 -1;
         -1 +0 -1 +1 +0 +0 -1 +0 +0 +0 +0 +1 +1 +0 +0 -1 -1 +0 +0]')
    const exit_face = int8(
        [dn rt rt up up up up lt dn dn rt lt dn lt lt dn up dn lt;
         lt dn lt rt rt dn lt up up up up rt rt dn dn lt lt up dn]')

    while length(cells) > 0
        case::Int8
        case0::Int8

        contour = ContourLine()

        # Helper functions
        
        # Given the row and column indices of the lower left
        # vertex, add the location where the contour level
        # crosses the specified edge.
        function add_vertex(row::Int, col::Int, edge::Int8, dir::Int8)
            if edge == lt
                yi = row + (h - z[row,col])/(z[row+1,col] - z[row,col])
                xi = col
            elseif edge == rt
                yi = row + (h - z[row,col+1])/(z[row+1,col+1] - z[row,col+1])
                xi = col + 1
            elseif edge == up
                yi = row + 1
                xi = col + (h - z[row+1,col])/(z[row+1,col+1] - z[row+1,col])
            elseif edge == dn
                yi = row
                xi = col + (h - z[row,col])/(z[row,col+1] - z[row,col])
            end
            if dir == ccw
                push!(contour.x, xi)
                push!(contour.y, yi)
            else
                unshift!(contour.x, xi)
                unshift!(contour.y, yi)
            end
        end

        # Given a starting cell and a search direction, keep adding
        # contour crossing until we close the contour or hit a boundary
        function chase(row::Int, col::Int, dir::Int8)
            while (row,col) != (r0,c0) && 0 < row < r_max && 0 < col < c_max
                case = cells[(row,col)]
                add_vertex(row,col,exit_face[case],dir)
                if case == 16
                    cells[(row,col)] = 4
                elseif case == 17
                    cells[(row,col)] = 13
                elseif case == 18
                    cells[(row,col)] = 2
                elseif case == 19
                    cells[(row,col)] = 11
                else
                    delete!(cells, (row,col))
                end
                (row,col) = (row + dir_r[case,dir], col + dir_c[case,dir])
            end
 
             return (row,col), case
        end
        
        # Pick initial box
        (r0, c0), case0 = first(cells)
        (r,c) = (r0,c0)
        case = case0
        
        # Add the contour entry location for cell (r0,c0)
        add_vertex(r0,c0,exit_face[case],cw)
        (r,c) = (r0 + dir_r[case,ccw], c0 + dir_c[case,ccw])
        if case < 15
            delete!(cells, (r0,c0))
        end

        # Start trace in CCW direction
        (r,c), case = chase(r,c,ccw)

        # Add the contour exit location for cell (r0,c0)
        if (r,c) != (r0,c0)
            (r,c) = (r0 + dir_r[case0,cw], c0 + dir_c[case0,cw])
        end

        # Start trace in CW direction
        chase(r,c,cw)
        push!(contours, contour)
    end

    return contours

end

end
