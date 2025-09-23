module SoilMoisture

using CSV, DataFrames, Dates, Glob, Plots, PrettyTables, Printf, StatsPlots, Statistics, Random, LinearAlgebra, NonlinearSolve
using NeuralPDE, Lux, Optimization, OptimizationOptimJL, LineSearches, Plots, ComponentArrays
using ModelingToolkit, NonlinearSolve
using DomainSets
import Interpolations: interpolate, Gridded, Linear, extrapolate, Line
using Random, Flux
using BSON: @save, @load


include("data.jl")
include("plots.jl")
include("num_methods.jl")
include("moisture_form_model.jl")
include("pressure_form_model.jl")
# include("irrigate.jl")

export list_station_files, var_depth_tokens, read_stm, merge_station_data, load_station_data, avg_sm, soil_params, avg_ts, sm_grad, preprocess
export plot_raw, plot_rainfall, plot_box, plot_violin, plot_line, basic_plots, avg_soil_moisture, plot_soil_retention_curve, plot_hydraulic_conductivity, plot_moisture_grad
export θ_to_ψ, ψ_to_θ, hydraulic_conductivity, darcy_law, conservation_mass, boundary_conditions, richards_1d_step, sim_1D_richards
end

