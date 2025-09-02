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
    """
    Plot raw rainfall with 0.05 soil moisure depth
    """
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

function plot_boxplot(df::DataFrame)
     
end

function plot_soil_moisture(df::DataFrame)
    
end

function plot_soil_temp(df::DataFrame)

end

# Example usage

station_dir = "data/XMS-CAT/Pessonada"
# station_dir = "data/test_station"
df = load_station_data(station_dir)

plot_r = plot_raw(df)
plot_p = plot_rainfall(df)

