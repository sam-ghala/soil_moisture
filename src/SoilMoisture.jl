module SoilMoisture

using CSV, DataFrames, Dates, Glob, Plots, PrettyTables, Printf, StatsPlots

include("data.jl")
include("plots.jl")
# include("model.jl")

# Export all the functions you want to be available when using SoilMoisture
# These are the functions from your tests:
export list_station_files, var_depth_tokens, read_stm, merge_station_data, load_station_data
export plot_raw, plot_rainfall, plot_box, plot_violin, plot_bar, plot_line, basic_plots, plot_soil_retention_curve, hydraulic_conductivity

end