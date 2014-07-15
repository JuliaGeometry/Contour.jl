using ImmutableArrays

# Setup test axes that will be shared among the tests

# Shift the axes so that they do not line up with
# integer values
Δ = 0.01
X = [0:Δ:4] + π
Y = [0:Δ:3] + φ

# TEST CASE 1
#
# f(x,y) = x^2 + y^2
#
Z = [(x^2 + y^2)::Float64 for x in X, y in Y]
h = rand()*(maximum(Z) - minimum(Z)) + minimum(Z)

contourlevels = Contour.contour(X,Y,Z, h)
for line in contourlevels.lines
    # Contour vertices lie on a circle around the origin
    for v in line.vertices
        @test_approx_eq_eps v[1]^2 + v[2]^2 h 0.1Δ
    end

    # coordinates() returns the correct values
    xs,ys = coordinates(line)
    xs .== [v[1] for v in line.vertices]
    ys .== [v[2] for v in line.vertices]
end

# TEST CASE 1.5
#
# Same as test case 1, but with a shifted center
#
h = 1
x0,y0 = (.5,-1.5)
Z = Float64[(x-x0)^2+(y-y0)^2 for x in X, y in Y]

contourlevels = Contour.contour(X, Y, Z, h)
for line in contourlevels.lines
    for v in line.vertices
        @test_approx_eq_eps ((v[1]-x0)^2 + (v[2]-y0)^2) h 0.01Δ
    end
end

# TEST CASE 2
#
# Check that ambigious cells (5, 10) are handled correctly
# Cell Case == 16
Z = float([1 0;
           0 1])
h = 0.5

cells = Contour.get_level_cells(Z,h)
@test cells[(1,1)] == 16
lines = Contour.trace_contour([1.0,2.0], [1.0,2.0], Z, h, cells).lines
@test length(lines) == 2

@test_approx_eq_eps lines[1].vertices[1] Vector2(1.0, 1.5) 0.1Δ
@test_approx_eq_eps lines[1].vertices[2] Vector2(1.5, 1.0) 0.1Δ

@test_approx_eq_eps lines[2].vertices[1] Vector2(2.0, 1.5) 0.1Δ
@test_approx_eq_eps lines[2].vertices[2] Vector2(1.5, 2.0) 0.1Δ

# Cell Case == 17
Z = float([2 0;
           0 2])
h = 0.5

cells = Contour.get_level_cells(Z,h)
@test cells[(1,1)] == 17
lines = Contour.trace_contour([1.0,2.0], [1.0,2.0], Z, h, cells).lines
@test length(lines) == 2

@test_approx_eq_eps lines[1].vertices[1] Vector2(1.0, 1.75) 0.1Δ
@test_approx_eq_eps lines[1].vertices[2] Vector2(1.25, 2.0) 0.1Δ

@test_approx_eq_eps lines[2].vertices[1] Vector2(2.0, 1.25) 0.1Δ
@test_approx_eq_eps lines[2].vertices[2] Vector2(1.75, 1.0) 0.1Δ

# Cell case == 18
Z = float([0 1;
           1 0])

cells = Contour.get_level_cells(Z,h)
@test cells[(1,1)] == 18
lines = Contour.trace_contour([1.0,2.0], [1.0,2.0], Z, h, cells).lines
@test length(lines) == 2

@test_approx_eq_eps lines[1].vertices[1] Vector2(1.5, 2.0) 0.1Δ
@test_approx_eq_eps lines[1].vertices[2] Vector2(1.0, 1.5) 0.1Δ

@test_approx_eq_eps lines[2].vertices[1] Vector2(1.5, 1.0) 0.1Δ
@test_approx_eq_eps lines[2].vertices[2] Vector2(2.0, 1.5) 0.1Δ


# Cell Case == 19
Z = float([0 2;
           2 0])

cells = Contour.get_level_cells(Z,h)
@test cells[(1,1)] == 19
lines = Contour.trace_contour([1.0,2.0], [1.0,2.0], Z, h, cells).lines
@test length(lines) == 2

@test_approx_eq_eps lines[1].vertices[1] Vector2(1.25, 1.0) 0.1Δ
@test_approx_eq_eps lines[1].vertices[2] Vector2(1.0, 1.25) 0.1Δ

@test_approx_eq_eps lines[2].vertices[1] Vector2(1.75, 2.0) 0.1Δ
@test_approx_eq_eps lines[2].vertices[2] Vector2(2.0, 1.75) 0.1Δ
