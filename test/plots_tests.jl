using Test
using SoilMoisture
using Dates, DataFrames, Plots
ENV["GKSwstype"] = "100"  # Graphics Kernel System, workstation type, (100) no output 
gr() # plotting backend, no display

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

@testset "plot_box" begin
    test_df = DataFrame(
            timestamp = [DateTime(2023,1,1,i) for i in 1:5],
            depth_10cm = [0.1, 0.15, 0.12, 0.18, 0.14],
            depth_20cm = [0.08, 0.12, 0.10, 0.15, 0.11],
            depth_30cm = [0.06, 0.09, 0.08, 0.12, 0.09]
        )
    plt = plot_box(test_df, names(test_df), "x_label", "y_label")
    # println(keys(plt.attr))
    # println(keys(plt.series_list[1]))
    @test plt isa Plots.Plot
    @test length(plt.series_list) == 12
    @test plt.attr[:size] == (900, 400)
end

@testset "plot_violin" begin
    test_df = DataFrame(
            timestamp = [DateTime(2023,1,1,i) for i in 1:5],
            depth_10cm = [0.1, 0.15, 0.12, 0.18, 0.14],
            depth_20cm = [0.08, 0.12, 0.10, 0.15, 0.11],
            depth_30cm = [0.06, 0.09, 0.08, 0.12, 0.09]
        )
    plt = plot_violin(test_df, names(test_df), "x_label", "y_label")
    # println(keys(plt.attr))
    # println(keys(plt.series_list[1]))
    @test plt isa Plots.Plot
    @test length(plt.series_list) == 8
    @test plt.attr[:size] == (900, 400)  
end

@testset "plot_line" begin
    test_df = DataFrame(
            timestamp = [DateTime(2023,1,1,i) for i in 1:5],
            depth_10cm = [0.1, 0.15, 0.12, 0.18, 0.14],
            depth_20cm = [0.08, 0.12, 0.10, 0.15, 0.11],
            depth_30cm = [0.06, 0.09, 0.08, 0.12, 0.09]
        )
    plt = plot_line(test_df, names(test_df), "x_label", "y_label")
    # println(keys(plt.attr))
    # println(keys(plt.series_list[1]))
    @test plt isa Plots.Plot
    @test length(plt.series_list) == 4
    @test plt.attr[:size] == (900, 400)
end

@testset "plot_bar" begin
    test_df = DataFrame(
            timestamp = [DateTime(2023,1,1,i) for i in 1:5],
            depth_10cm = [0.1, 0.15, 0.12, 0.18, 0.14],
            depth_20cm = [0.08, 0.12, 0.10, 0.15, 0.11],
            depth_30cm = [0.06, 0.09, 0.08, 0.12, 0.09]
        )
    plt = plot_bar(test_df, names(test_df), "x_label", "y_label")
    # println(keys(plt.attr))
    # println(keys(plt.series_list[1]))
    @test plt isa Plots.Plot
    @test length(plt.series_list) == 8
    @test plt.attr[:size] == (900, 400)
end

@testset "basic_plots" begin
    # generate some data
    test_df = DataFrame(
        timestamp = [DateTime(2023,1,1,i) for i in 1:10],
        sm_005 = rand(10) * 0.5,
        sm_010 = rand(10) * 0.4,
        ts_005 = rand(10) * 10 .+ 15,
        ts_010 = rand(10) * 8 .+ 12,
        ta_150 = rand(10) * 15 .+ 20,
        p_200 = rand(10) * 5
    )
    
    @testset "function returns correct type" begin
        plots = basic_plots(test_df)
        @test plots isa Vector
        @test all(p isa Plots.Plot for p in plots)
    end
    
    @testset "correct number of plots generated" begin
        plots = basic_plots(test_df)
        @test length(plots) == 10
    end
    
    @testset "skip logic works correctly" begin
        limited_df = DataFrame(
            timestamp = [DateTime(2023,1,1,i) for i in 1:5],
            ta_150 = rand(5) * 15 .+ 20,
            p_200 = rand(5) * 5
        )
        plots_limited = basic_plots(limited_df)
        
        @test length(plots_limited) == 4
        @test all(p isa Plots.Plot for p in plots_limited)
    end
end