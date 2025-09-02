# using StatsPlots
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
    plt = plot(; size = (900,400), xlabel = "Time", ylabel = "",
                title = "Raw data")
    for (i,col) in enumerate(depth_cols)
        plot!(plt, df.timestamp, df[!, col], label = String(col), color = cols[i],lw=2)
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
    plt = plot(; size = (900, 400), xlabel = "Time", ylabel= "θ (m^3/m^3)",
                title = "Rainfall and 0.05m Soil Moisture over Time")
    plot!(plt, df.timestamp, df[!, 3], label = String("0.05"), color = "saddlebrown",lw=1)
    bar!(twinx(plt), df.timestamp, df[!, Symbol("p_-2.000")]; 
        bar_width = 1,
        linecolor = "dodgerblue2",
        fillalpha = 1,
        label="Rain (mm)", 
        color = "dodgerblue2")
    display(plt)
    return plt
end

function plot_box(df::DataFrame, cols::Vector{String}, xlab::String, ylab::String)
    plt = plot(ylabel=ylab, 
               title=ylab,
               size=(900, 400))

    colors = reverse(palette(:viridis, length(cols))) # :viridis :plasma :inferno
    for (i, col) in enumerate(cols)
        boxplot!(plt, [i], df[!, col], label=col, color = colors[i], fillalpha=0.7)
    end
    
    plot!(plt, xticks=(1:length(cols), cols), legend=false)
    display(plt)
    return plt
end

function plot_violin(df::DataFrame, cols::Vector{String}, xlab::String, ylab::String)
    plt = plot(ylabel=ylab, 
               title=ylab,
               size=(900, 400))

    colors = reverse(palette(:viridis, length(cols))) # :viridis :plasma :inferno
    for (i, col) in enumerate(cols)
        violin!(plt, [i], df[!, col], label=col, color = colors[i], fillalpha=0.7)
    end
    
    plot!(plt, xticks=(1:length(cols), cols), legend=false)
    display(plt)
    return plt
end

function plot_line(df::DataFrame, cols::Vector{String}, xlab::String, ylab::String)
    plt = plot(size=(900, 400), 
              xlabel=xlab, 
              ylabel=ylab,
              title=ylab * " vs. " * xlab)
    
    colors = reverse(palette(:viridis, length(cols))) # :viridis :plasma :inferno
    for (i, col) in enumerate(cols)
        plot!(plt, df.timestamp, df[!, col], 
              label=col, color=colors[i], lw=2)
    end
    display(plt)
    return plt
end

function plot_bar(df::DataFrame, cols::Vector{String}, xlab::String, ylab::String)
    plt = plot(size=(900, 400), 
              xlabel=xlab, 
              ylabel=ylab,
              title=ylab * "  vs. " * xlab)
    
    for col in cols
        bar!(plt, df.timestamp, df[!, col], 
             label=col, alpha=0.7)
    end
    display(plt)
    return plt
end
"""
   basic_plots(df::DataFrame) -> Vector{Plots.Plot}

Generate multiple plot types for each variable group in a DataFrame.

Automatically groups DataFrame columns by variable type (sm, ts, ta, p) and creates
line, box, and violin plots for each group. Some plot types are skipped for certain
variables (e.g., no box plots for air temperature or precipitation).

# Arguments
- `df::DataFrame`: DataFrame with timestamp column (first) and sensor data columns

# Returns
- `Vector{Plots.Plot}`: Collection of plots for all variable types and plot combinations
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
    println(var_groups)
    haskey(var_groups, "sm") && (var_groups["Soil Moisture (m³/m³)"] = pop!(var_groups, "sm"))
    # var_groups["Soil Moisture (m^3/m^3)"] = pop!(var_groups, "sm")
    haskey(var_groups, "ta") && (var_groups["Air Temperature (°C)"] = pop!(var_groups, "ta"))
    haskey(var_groups, "ts") && (var_groups["Soil Temperature (°C)"] = pop!(var_groups, "ts"))
    haskey(var_groups, "p") && (var_groups["Precipitation (mm)"] = pop!(var_groups, "p"))

    plots = []
    var_names = keys(var_groups)

    funcs = Dict(
        "line" => plot_line,
        "box" => plot_box, 
        # "bar" => plot_bar,
        "violin" => plot_violin)
    skip = [("box", "Air Temperature (°C)"), ("bar", "Air Temperature (°C)"), 
            ("box", "Precipitation (m)"), ("bar", "Precipitation (m)"), 
            ("violin", "Precipitation (m)"), ("violin", "Air Temperature (°C)")]
    for (name, cols) in var_groups
        for (n, f) in funcs
            if (n,name) in skip
                continue
            end
            push!(plots, f(df, cols, "Time", name))
        end
    end
    # damn we need some more plots but above code is worth it 
    return plots
end

# Example usage
#
# station_dir = "data/XMS-CAT/Pessonada" # find a station
# df = load_station_data(station_dir)
# plots = basic_plots(df)
# plot_r = plot_raw(df)
# plot_p = plot_rainfall(df)
