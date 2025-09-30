"""
    plot_raw(df::DataFrame) -> Plots.Plot

Plot all columns (except timestamp) from a DataFrame as time series.

Creates a line plot with viridis colormap, displaying each non-timestamp column
as a separate series with automatic legend labels.

# Arguments
- `df::DataFrame`: DataFrame with timestamp column and numeric data columns

# Returns
- `Plots.Plot`: Plot object with all data series
"""
function plot_raw(df::DataFrame)
    depth_cols = names(df)[2:end]
    cmap = cgrad(:viridis) # :viridis :plasma :inferno
    n = length(depth_cols)
    cols =reverse([get(cmap, (i-1)/(n-1)) for i in 1:n])
    plt = Plots.plot(; size = (900,400), xlabel = "Time", ylabel = "",
                title = "Raw data")
    for (i,col) in enumerate(depth_cols)
        Plots.plot!(plt, df.timestamp, df[!, col], label = String(col), color = cols[i],lw=2)
    end    
    display(plt)
    return plt
end
"""
    plot_rainfall(df::DataFrame)
Plot rainfall data with shallow soil moisture overlay.
Creates a dual-axis plot showing 0.05m depth soil moisture as a line plot
and precipitation data as a bar chart on a secondary y-axis.

# Arguments
- 'df::DataFrame': DataFrame containing timestamp, soil moisture at 0.05m depth (3rd column),
and precipitation data in column "p_-2.000"

# Returns
- `Plots.Plot`: Plot object with precipitation and 0.050m soil moisture
"""
function plot_rainfall(df::DataFrame)
    plt = Plots.plot(; size = (900, 400), xlabel = "Time", ylabel= "θ (m^3/m^3)",
                title = "Rainfall and 0.05m Soil Moisture over Time")
    Plots.plot!(plt, df.timestamp, df[!, 3], label = String("0.05"), color = "saddlebrown",lw=1)
    Plots.bar!(twinx(plt), df.timestamp, df[!, Symbol("p_-2_000")]; 
        bar_width = 1,
        linecolor = "dodgerblue2",
        fillalpha = 1,
        label="Rain (mm)", 
        color = "dodgerblue2")
    display(plt)
    return plt
end

function plot_box(df::DataFrame, cols::Vector{String}, xlab::String, ylab::String)
    plt = Plots.plot(ylabel=ylab, 
               title=ylab,
               size=(900, 400))

    colors = reverse(palette(:viridis, length(cols))) # :viridis :plasma :inferno
    for (i, col) in enumerate(cols)
        Plots.boxplot!(plt, [i], df[!, col], label=col, color = colors[i], fillalpha=0.7)
    end
    
    Plots.plot!(plt, xticks=(1:length(cols), cols), legend=false)
    display(plt)
    return plt
end

function plot_violin(df::DataFrame, cols::Vector{String}, xlab::String, ylab::String)
    plt = Plots.plot(ylabel=ylab, 
               title=ylab,
               size=(900, 400))

    colors = reverse(palette(:viridis, length(cols))) # :viridis :plasma :inferno
    for (i, col) in enumerate(cols)
        Plots.violin!(plt, [i], df[!, col], label=col, color = colors[i], fillalpha=0.7)
    end
    
    Plots.plot!(plt, xticks=(1:length(cols), cols), legend=false)
    display(plt)
    return plt
end

function plot_line(df::DataFrame, cols::Vector{String}, xlab::String, ylab::String; title=nothing)
    isnothing(title) ? title = ylab * " vs. " * xlab : title
    plt = Plots.plot(size=(900, 400), 
              xlabel=xlab, 
              ylabel=ylab,
              title= title)
    
    colors = reverse(palette(:viridis, length(cols))) # :viridis :plasma :inferno
    for (i, col) in enumerate(cols)
        Plots.plot!(plt, df.timestamp, df[!, col], 
              label=col, color=colors[i], lw=2)
    end
    display(plt)
    return plt
end

"""
    basic_plots(df::DataFrame) -> Vector{Plots.Plot}

Generate multiple plot types for each variable group in a DataFrame.

"""
function basic_plots(df::DataFrame) # returns Vector{Plots.Plot}
    var_groups = Dict{String, Vector{String}}()
    for col in names(df)[2:end] 
        var_type = split(col, r"[_\d]")[1]
        if !haskey(var_groups, var_type)
            var_groups[var_type] = String[]
        end
        push!(var_groups[var_type], col)
    end
    # println(var_groups)
    haskey(var_groups, "sm") && (var_groups["Soil Moisture (m³/m³)"] = pop!(var_groups, "sm"))
    # var_groups["Soil Moisture (m^3/m^3)"] = pop!(var_groups, "sm")
    haskey(var_groups, "ta") && (var_groups["Air Temperature (°C)"] = pop!(var_groups, "ta"))
    haskey(var_groups, "ts") && (var_groups["Soil Temperature (°C)"] = pop!(var_groups, "ts"))
    haskey(var_groups, "p") && (var_groups["Precipitation (mm)"] = pop!(var_groups, "p"))

    plts = []
    # var_names = keys(var_groups)
    # print(var_names)
    funcs = Dict(
        "line" => plot_line,
        "box" => plot_box, 
        "violin" => plot_violin)
    skip = [("box", "Air Temperature (°C)"), ("bar", "Air Temperature (°C)"), 
            ("box", "Precipitation (mm)"), ("bar", "Precipitation (mm)"), 
            ("violin", "Precipitation (mm)"), ("violin", "Air Temperature (°C)")]
    for (name, cols) in var_groups
        for (n, f) in funcs
            if (n,name) in skip
                continue
            end
            push!(plts, f(df, cols, "Time", name))
        end
    end
    push!(plts, plot_line(df, ["avg_sm"], "Time", "Average Soil Moisture"))
    push!(plts, plot_line(df, ["avg_ts"], "Time", "Average Soil Temperature"))
    # damn we need some more plots but above code is worth it 
    return plts
end

function plot_soil_retention_curve()
    soil_types = ["sand", "loam", "clay", "silt"] 
    colors = reverse(palette(:viridis, 4))
    
    plt = Plots.plot(xlabel="Pressure head, ψ", 
              ylabel="Water content, θ",
              xscale=:log10,
              xlims=(0.01, 1000),
              ylims=(0, 0.45),
              title="Water retention curve",
              size=(600, 400))
    
    for (i, soil) in enumerate(soil_types)
        params = soil_params(soil)

        # pressure head
        ψ_range = 10 .^ range(log10(0.01), log10(1000), length=200)
        
        # get θ from ψ with inverse van Genuchten
        θ = @. params.θr + (params.θs - params.θr) * (1 + (params.α * ψ_range)^params.n)^(-params.m)
        
        Plots.plot!(plt, ψ_range, θ, 
              label=soil, 
              color=colors[i], 
              linewidth=2)
    end
    # display(plt)
    return plt
end

function plot_hydraulic_conductivity()
    soil_types = ["sand", "loam", "clay", "silt"] 
    colors = reverse(palette(:viridis, 4))
    
    plt = Plots.plot(xlabel="Pressure head, ψ", 
            ylabel="K [m/s]",
            xscale=:log10,
            yscale=:log10,
            xlims=(0.01, 1000),
            title="Hydraulic Conductivity",
            size=(600, 400))
    for (i, soil) in enumerate(soil_types)
        p = soil_params(soil)
        θr, θs, α, n, m, K_sat = p.θr, p.θs, p.α, p.n, p.m, p.K_sat

        # pressure head
        ψ_range = 10 .^ range(log10(0.01), log10(1000), length=200)
        
        # get θ from ψ with inverse van Genuchten
        θ = @. θr + (θs - θr) * (1 + (α * ψ_range)^n)^(-m)
        θe = @. (θ - θr) / (θs - θr)
        θe = clamp.(θe, 1e-6, 1 - 1e-6)
        #
        K_θ = @. K_sat * θe^0.5 * (1 - (1 - θe^(1/m))^m)^2

        Plots.plot!(plt, ψ_range, K_θ, 
              label=soil, 
              color=colors[i], 
              linewidth=2)
    end
    # display(plt)
    return plt
end

function plot_moisture_grad(df::DataFrame)
    plot_line(df, [:"grad_05_20", :"grad_20_50", :"grad_50_1"], "Time", "∂θ/∂z [m²/m³]")
end

# Example usage:
#
# station_dir = "data/XMS-CAT/Pessonada" # find a station
# df = preprocess(station_dir)
# plots = basic_plots(df)
# plot_r = plot_raw(df)
# plot_p = plot_rainfall(df)

# More fun plots =>

# plot_soil_retention_curve()
# plot_hydraulic_conductivity()
# plot_moisture_grad(df)
# station_data = load_all_stations()

# rewrite the plotting functions above to get what actually matters 

# for (k,v) in station_data
#     cols = get_same_col_names(v, "sm")
#     plot_line(v, cols, "time", "moisture", title=k)
# end