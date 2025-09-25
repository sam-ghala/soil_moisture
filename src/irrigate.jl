mutable struct CropSpec
    name::String
    depth::Float64
    θ_crit::Float64
    θ_fc::Float64
    mad::Float64
    θ_trigger::Float64
end

crops = Dict(
    "shallow" => CropSpec("Lettuce/Grass", 0.3, 0.15, 0.35, 0.4, NaN),
    "medium"  => CropSpec("Tomato/Pepper", 0.6, 0.12, 0.35, 0.5, NaN),
    "deep" => CropSpec("Corn/Tree", 1.0, 0.10, 0.35, 0.6, NaN)
)

function root_zone_avg!(df_sensor, df_irr, CROPS)
    # 
    df_irr[!, :θ_avg_shallow] = zeros(nrow(df_irr))
    df_irr[!, :θ_avg_medium] = zeros(nrow(df_irr))
    df_irr[!, :θ_avg_deep] = zeros(nrow(df_irr))
    #
    for (idx, row) in enumerate(eachrow(df_irr))
        # println(idx, row.timestamp)
        f = load_moisture_profile(df_sensor, row.timestamp)
    #
        for (crop_type, info) in CROPS
            avg_moisture, _ = quadgk(f, 0.0, info.depth) 
            avg_moisture /= (info.depth - 0.0)
            col_name = Symbol("θ_avg_$(crop_type)")
            df_irr[idx, col_name] = avg_moisture
        end
    end
end

function avialable_water!(crops)
    for (crop_type, info) in crops
        θ_fc, θ_crit, mad = info.θ_fc, info.θ_crit, info.mad
        θ_trigger = θ_fc - (θ_fc - θ_crit) * mad
        crops[crop_type].θ_trigger = θ_trigger
    end
end

function θ_trigger_threshold!(df_irr, crops) # true is needs irrigation 
    df_irr[!, :θ_shallow_trigger] .= df_irr.θ_avg_shallow .< crops["shallow"].θ_trigger
    df_irr[!, :θ_medium_trigger] .= df_irr.θ_avg_medium .< crops["medium"].θ_trigger
    df_irr[!, :θ_deep_trigger] .= df_irr.θ_avg_deep .< crops["deep"].θ_trigger
end

function plot_irrigate(df, df_irr)
    depth_labels = ["sm_0.050", "sm_0.200", "sm_0.500", "sm_1.000"]
    colors = reverse(palette(:viridis, 4))
    plt = plot(size=(900, 400), 
                title = "SM Threshold",
                xlabel = "Time (hours)",
                ylabel = "Moisture (m^3/m^3)",
                legend=false)
    # plot sensor data
    # for i in 1:4
    #     plot!(plt, df[!, :timestamp], df[!, Symbol(depth_labels[i])], label=depth_labels[i], color=colors[i], lw=2)
    # end
    # plot crop irrigation
    plot_trigger_line!(plt, df_irr, :θ_avg_shallow, :θ_shallow_trigger; base_color=:blue)
    plot_trigger_line!(plt, df_irr, :θ_avg_medium,  :θ_medium_trigger;  base_color=:blue)
    plot_trigger_line!(plt, df_irr, :θ_avg_deep,    :θ_deep_trigger;    base_color=:blue)

    display(plt)
end

function build_irr_df(df, crops)
    df_irr = DataFrame()
    df_irr.timestamp = copy(df.timestamp)
    root_zone_avg!(df, df_irr, crops)
    avialable_water!(crops)
    θ_trigger_threshold!(df_irr, crops)
    return df_irr
end

# station_dir = "data/XMS-CAT/Pessonada"
# df_sensor = preprocess(station_dir)
# df_irr = build_irr_df(df_sensor, crops)
# station_names = load_station_names()
# for s in station_names
#     println(s)
#     df_sensor = preprocess(s)
#     df_irr = build_irr_df(df_sensor, crops)
#     plot_irrigate(df_sensor, df_irr)
# end


## little helper function, need an easier way to visualize when crops below θ threshold
function plot_trigger_line!(plt, df, avg_col, trig_col; base_color=:blue)
    x = df.timestamp
    y = df[!, avg_col]
    trig = df[!, trig_col]

    start_idx = 1
    for i in 2:length(trig)
        if trig[i] != trig[i-1] || i == length(trig)
            seg_x = x[start_idx:(i-1)]
            seg_y = y[start_idx:(i-1)]
            color = trig[i-1] ? :red : base_color
            plot!(plt, seg_x, seg_y; color=color, lw=3, label="")
            start_idx = i
        end
    end
end
