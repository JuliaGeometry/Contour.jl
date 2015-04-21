using ImmutableArrays

# Setup test axes that will be shared among the tests

# Shift the axes so that they do not line up with
# integer values
Δ = 0.01
X = collect(0:Δ:4) + π
Y = collect(0:Δ:3) + φ

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
# Case 5: z_center > h
X = [1.0,2.0]
Y = [2.0,1.0]

Z = float([1 0;
           0 1])
h = 0.1

lines = Contour.contour(X, Y, Z, h).lines
@test length(lines) == 2

for line in lines
    @test length(line.vertices) == 2
    Δ = line.vertices[2] - line.vertices[1]
    @test_approx_eq Δ[2]/Δ[1] -1.0
end

# Case 5: z_center < h
Z = float([1 0;
           0 1])
h = 0.9

lines = Contour.contour(X, Y, Z, h).lines

@test length(lines) == 2

for line in lines
    @test length(line.vertices) == 2
    Δ = line.vertices[2] - line.vertices[1]
    @test_approx_eq Δ[2]/Δ[1] 1.0
end

# Case 10: z_center > h
Z = float([0 1;
           1 0])
h = 0.1

lines = Contour.contour(X, Y, Z, h).lines
@test length(lines) == 2

for line in lines
    @test length(line.vertices) == 2
    Δ = line.vertices[2] - line.vertices[1]
    @test_approx_eq Δ[2]/Δ[1] 1.0
end

# Case 10: z_center < h

Z = float([0 1;
           1 0])
h = 0.9

lines = Contour.contour(X, Y, Z, h).lines
@test length(lines) == 2

for line in lines
    @test length(line.vertices) == 2
    Δ = line.vertices[2] - line.vertices[1]
    @test_approx_eq Δ[2]/Δ[1] -1.0
end

# Test Known Bugs

# Issue #12
x = float(collect(1:3));
y = copy(x); 
z = eye(3,3);
contours(x,y,z)

# Test handling of saddle points
#
# f(x,y) = x^2 - y^2
#
Δ = 0.01
X = collect(-3:Δ:3)
Y = collect(-3:Δ:3)

Z = [(x^2 - y^2)::Float64 for x in X, y in Y]
h = rand()*(maximum(Z) - minimum(Z)) + minimum(Z)

contourlevels = Contour.contour(X,Y,Z, h)
for line in contourlevels.lines
    # Contour vertices lie on a circle around the origin
    for v in line.vertices
        @test_approx_eq_eps v[1]^2 - v[2]^2 h 0.1Δ
    end

    # coordinates() returns the correct values
    xs,ys = coordinates(line)
    xs .== [v[1] for v in line.vertices]
    ys .== [v[2] for v in line.vertices]
end

# Test that closed contours are identified correctly 
# when ambiguous cells are involved

Z = float([1 1 1 1 1 1
           1 0 0 1 1 1
           1 0 0 1 1 1
           1 1 1 0 0 1
           1 1 1 0 0 1
           1 1 1 1 1 1])

X = Y = collect(0:0.2:1)
h = 0.75
contourlevels = Contour.contour(X,Y,Z,h)

# There should be only one closed contour
@test length(contourlevels.lines) == 1

# Test contour location on a realistic dataset
include("testdata.jl")
Contour.contours(x,y,z)
