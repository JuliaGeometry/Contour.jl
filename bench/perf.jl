using BenchmarkTools
using Contour
using StaticArrays
using Test
#using Plots

const suite = BenchmarkGroup()
suite["contour"] = BenchmarkGroup()

#circle(v, r) = sqrt(sum(v.^2)) - r

include(joinpath(@__DIR__,"../test/testdata.jl"))
v = Contour.contours(x, y, z)
@show typeof(v)

suite["contour"]["chase"] = @benchmarkable Contour.contours($x,$y,$z, 10)
suite["contour"]["edge_list"] = @benchmarkable Contour.contours($x,$y,$z, 10, Contour.MSEdges())


results = run(suite)

for trial in results
    ctx = IOContext(stdout, :verbose => true, :compact => false)
    println(ctx)
    println(ctx, trial.first)
    println(ctx, trial.second)
end
