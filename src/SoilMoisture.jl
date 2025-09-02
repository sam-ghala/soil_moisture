module SoilMoisture

using CSV, DataFrames, Dates, Glob, Plots, PrettyTables, Printf

include("data.jl")
include("plots.jl")

# Export all the functions you want to be available when using SoilMoisture
# These are the functions from your tests:
export list_station_files, var_depth_tokens, read_stm, merge_station_data, load_station_data
export plot_raw, plot_rainfall, plot_boxplot, plot_soil_moisture, plot_soil_temp

end