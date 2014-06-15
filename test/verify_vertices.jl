using Contour
using Base.Test

using Grid

# Setup test axes that will be shared among the tests
Δ = 0.01
X = [-2:Δ:2]
Y = [-3:Δ:3]

X_c = InterpGrid(X, BCnan, InterpLinear)
Y_c = InterpGrid(Y, BCnan, InterpLinear)

function circle()
    Z = [x^2 + y^2 for y in Y, x in X]
    # Choose level that is at least on grid size away from origin
    h = (Δ + (3 - Δ)rand())
    lines = Contour.contours(X,Y,Z, h)
    for l in lines
        R2 = X_c[l.x].^2 + Y_c[l.y].^2
        for r2 in R2
            @test_approx_eq_eps(r2, h, 0.1Δ)
        end
    end
end

circle()
