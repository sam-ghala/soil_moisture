using Test
using SoilMoisture
using Dates, DataFrames, Plots

@testset "plot_raw" begin
    # generate data
    test_df = DataFrame(
            timestamp = [DateTime(2023,1,1,i) for i in 1:5],
            depth_10cm = [0.1, 0.15, 0.12, 0.18, 0.14],
            depth_20cm = [0.08, 0.12, 0.10, 0.15, 0.11],
            depth_30cm = [0.06, 0.09, 0.08, 0.12, 0.09]
        )
    plt = plot_raw(test_df)
    # println(keys(plt.attr))
    # println(keys(plt.series_list[1]))
    @test plt isa Plots.Plot
    @test length(plt.series_list) == 3
    @test plt.attr[:size] == (900, 400)
end

@testset "plot_rainfall" begin
    test_df = DataFrame(
        timestamp = [DateTime(2023,1,1,i) for i in 1:5],
        depth_10cm = [0.1, 0.15, 0.12, 0.18, 0.14],
        sm_005 = [0.08, 0.12, 0.10, 0.15, 0.11],
        depth_20cm = [0.06, 0.09, 0.08, 0.12, 0.09]
    )
    test_df[!, "p_-2.000"] = [2.0, 0.0, 5.5, 1.2, 0.0]

    plt = plot_rainfall(test_df)
    # println(keys(plt.attr))
    # println(keys(plt.series_list[1]))
    @test plt isa Plots.Plot
    @test length(plt.series_list) == 3
    @test plt.attr[:size] == (900, 400)
end

@testset "plot_boxplot" begin
    
end

@testset "plot_soil_moisture" begin
    
end

@testset "plot_soil_temp" begin
    
end