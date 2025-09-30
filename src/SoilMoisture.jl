module SoilMoisture

import BSON
using CSV, DataFrames, Dates, Glob, Plots, PrettyTables, Printf, StatsPlots, Statistics, Random, LinearAlgebra, NonlinearSolve
using NeuralPDE, Lux, Optimization, OptimizationOptimJL, LineSearches, Plots, ComponentArrays
using ModelingToolkit, NonlinearSolve
using DomainSets
import Interpolations: interpolate, Gridded, Linear, extrapolate, Line
using Random, Flux
using BSON: @save, @load
using Glob


include("data.jl")
include("plots.jl")
include("num_methods.jl")
include("moisture_form_model.jl")
include("pressure_form_model.jl")
include("irrigate.jl")

end

