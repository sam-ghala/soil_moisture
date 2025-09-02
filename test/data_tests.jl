using Test
using SoilMoisture
# using DataFrames, Dates

@testset "list_station_files" begin
    # dir = "data/test_station"
    # non_stm = "data/test_station/XMS-CAT_XMS-CAT_Pessonada_static_variables.csv"
    # ex_stm = "data/test_station/XMS-CAT_XMS-CAT_Pessonada_sm_0.200000_0.200000_CS655_20240825_20250825.stm"
    # #
    # dir = "/Users/samghalayini/agriculture/soil_moisture/data/test_station"
    # non_stm = "/Users/samghalayini/agriculture/soil_moisture/ata/test_station/XMS-CAT_XMS-CAT_Pessonada_static_variables.csv"
    # ex_stm = "/Users/samghalayini/agriculture/soil_moisture/data/test_station/XMS-CAT_XMS-CAT_Pessonada_sm_0.200000_0.200000_CS655_20240825_20250825.stm"
    #
    dir = joinpath(@__DIR__, "..", "data", "test_station")
    non_stm = joinpath(@__DIR__, "..", "data", "test_station", "XMS-CAT_XMS-CAT_Pessonada_static_variables.csv")
    ex_stm = joinpath(@__DIR__, "..", "data", "test_station", "XMS-CAT_XMS-CAT_Pessonada_sm_0.200000_0.200000_CS655_20240825_20250825.stm")
    #
    files = list_station_files(dir)
    # println(files)
    # valid absolute path(from root)
    @test all(ispath, files)
    # file exists
    @test all(isfile, files)
    # only .stm extension
    @test all(endswith.(files, ".stm"))
    # does not include the .csv in test_station
    @test !(non_stm in files)
    # test_station has 6 .stm files
    @test length(files) == 6
    # Returns full paths
    @test all(p -> startswith(p, dir), files)
end

@testset "var_depth_tokens" begin
    dir = joinpath(@__DIR__, "..", "data", "test_station")
    files = list_station_files(dir)
    tokens = var_depth_tokens(files)
    # println(tokens)
    @test length(tokens) == 6
    @test tokens == ["p_-2.000", "sdf_1.000", "sm_0.200", "sm_0.500", "ta_-2.000", "ts_1.000"]
    @test all(t -> occursin(r"^.+_-?\d+\.\d{3}$", t), tokens)
end

@testset "read_stm" begin
    # file = "data/test_station/XMS-CAT_XMS-CAT_Pessonada_sm_0.200000_0.200000_CS655_20240825_20250825.stm"
    file = joinpath(@__DIR__, "..", "data", "test_station", "XMS-CAT_XMS-CAT_Pessonada_sm_0.200000_0.200000_CS655_20240825_20250825.stm")
    df = read_stm(file)
    @test string(typeof(df)) == "DataFrames.DataFrame"
    @test string(typeof(df.timestamp[1])) == "Dates.DateTime"
    @test size(df, 2) == 2
    @test names(df) == ["timestamp", "theta"]
    # @test eltype(df.timestamp) == DateTime
    @test eltype(df.theta) == Float64
    @test all(ismissing.(df.timestamp) .== false)
    @test all(ismissing.(df.theta) .== false)
    @test issorted(df.timestamp)
end

@testset "merge_station_data" begin
    dir = joinpath(@__DIR__, "..", "data", "test_station")
    files = list_station_files(dir)
    tokens = var_depth_tokens(files)
    df = merge_station_data(files, tokens)
    @test string(typeof(df)) == "DataFrames.DataFrame"
    @test size(df, 2) == length(tokens) + 1 # +1 for timestamp
    @test names(df) == ["timestamp"; tokens]
    # @test eltype(df.timestamp) == DateTime
    @test string(typeof(df.timestamp[1])) == "Dates.DateTime"
    @test all(ismissing.(df.timestamp) .== false)
    @test issorted(df.timestamp)
end

@testset "load_station_data" begin
    dir = joinpath(@__DIR__, "..", "data", "test_station")
    df = load_station_data(dir)
    @test string(typeof(df)) == "DataFrames.DataFrame"
    # @test ncol(df) == 7
    @test size(df, 2) == 7
    @test names(df) == ["timestamp", "p_-2.000", "sdf_1.000", "sm_0.200", "sm_0.500", "ta_-2.000", "ts_1.000"]
    @test string(typeof(df.timestamp[1])) == "Dates.DateTime"
    # @test eltype(df.timestamp) == DateTime
    @test issorted(df.timestamp)
end