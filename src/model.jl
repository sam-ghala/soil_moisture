Random.seed!(42)
# addprocs(4)  # Use multiple cores

function plot_solution(phi, res, duration)
    z_grid = 0.0:0.01:1.0
    t_grid = 0.0:(duration/200):duration
    # t_grid = 0.0:1000:86400.0
    u_predict = [first(phi([z, t], res.u)) for z in z_grid, t in t_grid]
    plt = heatmap(t_grid, z_grid, u_predict, yflip=true, color=:blues, xlabel="Time", ylabel="Depth")
    display(plt)
end

function plot_pred_profile(depths,moisture)
    plt = Plots.plot(size=(900, 400), 
              xlabel="Depth", 
              ylabel="Moisture",
              title="Moisture vs. Depth")
    Plots.plot!(plt, depths, moisture, 
              label="Moisture Profile", color=:blue, lw=2)
    display(plt)
end

function plot_moisture_comparison(phi, res, df, date, duration)
    # plot avg of real soil data, and plot avg or predicted soil data
    depths = [0.05, 0.20, 0.50, 1.0]
    depth_labels = ["sm_0.050", "sm_0.200", "sm_0.500", "sm_1.000"]
    time_points = 0:3600:duration
    colors = reverse(palette(:viridis, 4))
    # get sensor data for date range
    end_date = date + Second(duration)
    sensor_data = filter(row -> date <= row.timestamp <= end_date, df)
    sm_data = []
    # plot
    plt = plot(title = "Predicted vs. Observed Moisture Data",
                xlabel = "Time (hours)",
                ylabel = "Moisture (m^3/m^3)",
                legend=false)
    hours = time_points ./ 3600
    # plot sensor data
    for i in 1:4
        plot!(plt, hours, sensor_data[!, Symbol(depth_labels[i])], label=depth_labels[i], color=colors[i], lw=2)
    end
    # plot predicted data
    for i in 1:4
        pred_moisture = [first(phi([depths[i], t], res.u)) for t in time_points]
        plot!(plt, hours, pred_moisture, 
              label="Predicted $(depths[i])m", color=colors[i], lw=2, 
              linestyle=:dash, marker=:circle, markersize=3)
    end
    display(plt)
end

function K_simple(θ_val)
    K_dry = 1e-8
    K_wet = 1e-5
    return K_dry + (K_wet - K_dry) * ((θ_val - 0.29) / (0.35 - 0.29))^2
end

function ψ(θ_val)
    θe = (θ_val - θr) / (θs - θr)
    ψ = (1/α) * ((θe^(-1/m) - 1)^(1/n))
    return ψ
end

function D_eff(θ_val)
    K_val = K_simple(θ_val)
    return K_val * (1.0 + (θ_val - 0.29) / (0.35 - 0.29))
end

function get_sensor_values(df, date=nothing)
    if isnothing(date)
        date = DateTime("2024-12-01T00:00:00")
    elseif date == "random"
        date = rand(df.timestamp)
    elseif date == "test"
        return [0.15, 0.165, 0.197, 0.25]
    else
        date = DateTime(date)
    end
    row = filter(r -> r.timestamp == date, df)
    return collect(row[1, [:"sm_0.050", :"sm_0.200", :"sm_0.500", :"sm_1.000"]])
end

function load_moisture_profile(df, date=nothing)
    sensor_values = get_sensor_values(df, date)
    sensor_depths = [0.05, 0.20, 0.5, 1.0]
    itp = interpolate((sensor_depths,), sensor_values, Gridded(Linear()))
    etp = extrapolate(itp, Line())
    return x -> etp(clamp(x, 0.0, 1.0))
end

function predict_moisture_profile(phi, res, duration)
    depths = 0.0:0.05:1.0 # every 5cm 
    moisture = [first(phi([z, duration], res.u)) for z in depths]
    return depths, moisture
end

function setup_network_discretization()
    dim = 2 # depth and time
    chain = Chain(Dense(dim, 32, tanh), Dense(32, 32, tanh), Dense(32, 32, tanh), Dense(32, 1))
    # chain = Chain(Dense(dim, 32, tanh), Dense(32, 32, tanh), Dense(32, 1))

    discretization = PhysicsInformedNN(
        chain, QuadratureTraining(;
            batch = 2000, # 1000
            abstol = 1e-5, # e-5
            reltol = 1e-5, # e-5
        )
    )
    return discretization
end

function setup_conditions(θ, z, t, Dz, duration, sensor_profile, future_profile=nothing)
    z_ic = range(0.0, 1.0, length=50)
    ic_points = [ θ(zi, 0.0) ~ sensor_profile(zi) for zi in z_ic ]
    future_sample_points = [θ(zi,(0.5 * duration)) ~ future_profile(zi) for zi in z_ic]
    bcs = [
        θ(0, t) ~ 0.15 * (t <1800) + 0.13 * (t >=1800)
        θ(1.0, t) ~ 0.25 
        ]
    ret = vcat(bcs, ic_points, future_sample_points)
    domains = [z ∈ (0.0, 1.0), t ∈ (0.0, duration)]
    return ret, domains
end

function solve_pinn(df, duration=3600.0, date=nothing)
    θr, θs, α, n, m, K_sat =0.078, 0.43, 3.6, 1.56, 0.359, 2.9e-5
    @parameters z t
    @variables θ(..)
    Dz = Differential(z)
    Dt = Differential(t)

    # eq = Dt(θ(z, t)) ~ Dz(K_simple(θ(z, t)) * Dz(θ(z, t))) - K_simple(θ(z, t)) * 1.0
    eq = Dt(θ(z, t)) ~ Dz(D_eff(θ(z, t)) * Dz(θ(z, t))) - K_simple(θ(z, t)) * 1.0

    sensor_profile = load_moisture_profile(df, date)
    future_profile = load_moisture_profile(df, date + Month(1))
    bcs, domains = setup_conditions(θ, z, t, Dz, duration, sensor_profile, future_profile)

    discretization = setup_network_discretization()
    @named pde_system = PDESystem(eq, bcs, domains, [z, t], θ(z, t))
    prob = discretize(pde_system, discretization)

    opt = LBFGS(linesearch=LineSearches.BackTracking())
    res = solve(prob, opt, maxiters = 1000) # 1000
    phi = discretization.phi

    pred_depths, pred_moisture = predict_moisture_profile(phi, res, duration)
    plot_pred_profile(pred_depths, pred_moisture)
    plot_solution(phi, res, duration)
    plot_moisture_comparison(phi, res, df, date, duration)
    print("done")
end

# station_dir = "data/XMS-CAT/Pessonada"
# date = DateTime("2024-12-01T00:00:00")
# df = preprocess(station_dir)
#
solve_pinn(df, (3600.0 * 100), date)