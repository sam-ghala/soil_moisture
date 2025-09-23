# lets try a pressure head form to avoid uniform solutions
# Random.seed!(42)

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

function plot_solution(phi, res, duration, α=1.0)
    z_grid = 0.0:0.01:1.0
    t_grid = 0.0:(duration/200):duration
    ψ_predict = [first(phi([z, t], res.u)) for z in z_grid, t in t_grid]
    ψ_dimensional = ψ_predict ./ α
    θ_predict = ψ_θ.(ψ_dimensional)
    # plt = heatmap(t_grid ./ 3600, z_grid, θ_predict, yflip=true, color=:blues, xlabel="Time", ylabel="Depth", title="Moisture Content from Pressure Solution")
    plt1 = heatmap(t_grid ./ 3600, z_grid, θ_predict, 
                   yflip=true, color=:blues, 
                   xlabel="Time (hours)", ylabel="Depth (m)", 
                   title="Moisture Content",
                   clim=(0.05, 0.45))
    
    # Plot pressure head
    plt2 = heatmap(t_grid ./ 3600, z_grid, ψ_predict, 
                   yflip=true, color=:viridis,
                   xlabel="Time (hours)", ylabel="Depth (m)", 
                   title="Pressure Head (m)",
                   clim=(-10, 0))
    
    # plot(plt1, plt2, layout=(1,2), size=(1200, 400))
    # display(plt1)
    display(plt2)
end

function ψ_θ(ψ_val, θr=0.078, θs=0.43, α=3.6, n=1.56, m=0.359)
    if ψ_val >= 0
        return θs
    else
        θe = (1 + (α * abs(ψ_val))^n)^(-m)
        return θr + (θs - θr) * θe
    end
end

function θ_ψ(θ_val, θr=0.078, θs=0.43, α=3.6, n=1.56, m=0.359)
    θe = clamp((θ_val - θr) / (θs - θr), 0.001, 0.999)
    if θe >= 0.999
        return -0.001
    else
        return -(1/α) * ((θe^(-1/m) - 1)^(1/n))
    end
end

function setup_network_discretization(profile=:development)
    profiles = Dict(
        :minimal => ([2, 16, 16, 1], 500),
        :development => ([2, 32, 32, 32, 1], 1500),
        :production => ([2, 64, 64, 32, 1], 3000)
    )
    layers, batch = profiles[profile]
    chain_layers = []
    for i in 1:(length(layers)-1)
        if i == length(layers) - 1 
            push!(chain_layers, Dense(layers[i], layers[i + 1]))
        else
            push!(chain_layers, Dense(layers[i], layers[i + 1], tanh))
        end
    end

    chain = Chain(chain_layers...)

    discretization = PhysicsInformedNN(
        chain, QuadratureTraining(;
            batch = batch,
            abstol = 1e-5,
            reltol = 1e-5,
        )
    )
    return discretization
end

function setup_conditions(ψ, z, t, duration, sensor_profile)
    # 0.15 dry on top , 0.27 wet on bottom
    ψ_bottom = θ_ψ(0.27)
    t_bc = range(0.0, duration, length=20)
    bcs = []
    ic_points = []
    z_ic = range(0.0, 1.0, length=50)
    for zi in z_ic
        θ_init = sensor_profile(zi)
        ψ_init = θ_ψ(θ_init)
        push!(ic_points, ψ(zi, 0.0) ~ ψ_init)
    end
    for ti in t_bc
        θ_surface = 0.15 + 0.005 * (ti / duration)
        ψ_surface = θ_ψ(θ_surface)
        push!(bcs, ψ(0.0, ti) ~ ψ_surface)
        push!(bcs, ψ(1.0, ti) ~ ψ_bottom)
    end
    ret = vcat(bcs, ic_points)
    domains = [z ∈ (0.0, 1.0), t ∈ (0.0, 1.0)] # duration instead of t 1.0
    return ret, domains
end

function solve_with_monitoring(prob, opt; maxiters=1000, print_every=50)
    iteration = 0
    loss_history = Float64[]
    
    callback = function(p, l)
        iteration += 1
        push!(loss_history, l)

        if iteration % print_every == 0
            println("Iter $iteration | Loss: $(round(l, sigdigits=6)) | ")
        end
        
        if length(loss_history) > 100
            recent_avg = mean(loss_history[end-50:end])
            old_avg = mean(loss_history[end-100:end-51])
            if abs(recent_avg - old_avg) / old_avg < 1e-3
                println("Early stopping: Loss plateaued")
                return true
            end
        end
        
        return false
    end
    
    println("Starting optimization with $(maxiters) max iterations...")
    res = solve(prob, opt, callback=callback, maxiters=maxiters)
    
    return res, loss_history
end

function solve_pinn(df, duration=3600.0, date=nothing, profile=:development; 
                    model_path::Union{Nothing,String}=nothing, save_model::Bool=true)
    θr, θs, α, n, m, K_sat =0.078, 0.43, 3.6, 1.56, 0.359, 2.9e-5
    @parameters z t
    @variables ψ(..)
    Dz = Differential(z)
    Dt = Differential(t)
    ϵ = 1e-10
    # Richards Equation in Pressure form
    ψ_actual = -exp(ψ(z,t))
    h_pos = -ψ_actual  # Positive value for calculations
    Se_vg = (1 + (α * h_pos)^n)^(-m)
    Se = 0.01 + 0.98 * Se_vg
    Se_1m = Se^(1/m)
    K_ψ = K_sat * sqrt(Se) * (1 - (1 - Se_1m)^m)^2
    C_base = (θs - θr) * α * n * m * (α * h_pos)^(n-1) * (1 + (α * h_pos)^n)^(-m-1)
    C_min = 1e-5
    C_ψ = C_base + C_min
    eq = (1/duration) * C_ψ * (-exp(ψ(z,t))) * Dt(ψ(z,t)) ~ Dz(K_ψ * (-exp(ψ(z,t)) * Dz(ψ(z,t)) + 1.0))

    sensor_profile = load_moisture_profile(df, date)
    bcs, domains = setup_conditions(ψ, z, t, duration, sensor_profile)

    discretization = setup_network_discretization(profile) # :minimal, :development, :production
    @named pde_system = PDESystem(eq, bcs, domains, [z, t], ψ(z, t))
    prob = discretize(pde_system, discretization)    

    if !isnothing(model_path) && isfile(model_path)
        println("Loading pretrained model from $model_path")
        saved_data = BSON.load(model_path)
        if haskey(saved_data, :save_data)
            saved_data = saved_data[:save_data]
        end
        if haskey(saved_data, :params)
            saved_params = saved_data[:params]
            if isa(saved_params, ComponentArray)
                saved_params = Vector(saved_params)
            end
            if length(saved_params) == length(prob.u0)
                if isa(prob.u0, ComponentArray)
                    new_u0 = ComponentArray(saved_params, getaxes(prob.u0))
                    prob = remake(prob, u0=new_u0)
                else
                    prob = remake(prob, u0=saved_params)
                end
                println("Loaded $(length(saved_params)) parameters successfully")
            else
                println("Warning: Parameter mismatch - saved: $(length(saved_params)), expected: $(length(prob.u0))")
            end
        else
            println("Warning: No params found in saved file")
        end
    end

    opt = LBFGS(linesearch=LineSearches.BackTracking())
    res, loss_history = solve_with_monitoring(prob, opt, maxiters=200, print_every=20)
    phi = discretization.phi

    if save_model && res.objective < 10.0
        savepath = "pinn_model_$(duration/3600)hr.bson" # rewrite current model if I run it on same 
        params_to_save = isa(res.u, ComponentArray) ? Vector(res.u) : res.u
        save_data = Dict(
            :params => params_to_save,
            :loss => res.objective,
            :duration => duration)
        BSON.@save savepath save_data
        println("Model saved to $savepath ($(length(params_to_save)) parameters)")
    end
    # plots
    plot_solution(phi, res, duration)
end

# station_dir = "data/XMS-CAT/Pessonada"
# date = DateTime("2024-12-01T00:00:00")
# df = preprocess(station_dir)

# @time solve_pinn(df, (3600.0 * 1), date, :development)
# @time solve_pinn(df, (3600.0 * 1000), date, :development, model_path="pinn_model_100.0hr.bson")



# bike ride for goals, get food, continue bike ride, get food, stop by at home 