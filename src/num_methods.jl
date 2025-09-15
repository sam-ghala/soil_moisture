function θ_to_ψ(θ, p)
    θr, θs, α, n, m = p.θr, p.θs, p.α, p.n, p.m
    θe = @. (θ - θr) / (θs - θr)
    θe = clamp.(θe, 0.001, 0.999)
    ψ = @. (1/α) * ((θe^(-1/m) - 1)^(1/n))
    return ψ
end

function ψ_to_θ(ψ, p)
    θr, θs, α, n, m = p.θr, p.θs, p.α, p.n, p.m
    θ = @. abs(θr + (θs - θr) * (1 + (α * ψ)^n)^(-m))
    return θ
end

function hydraulic_conductivity(θ, p)
    θr, θs, α, n, m, K_sat = p.θr, p.θs, p.α, p.n, p.m, p.K_sat
    θe = @. (θ - θr) / (θs - θr)
    θe = clamp.(θe, 0.001, 0.999)
    K_θ = @. K_sat * θe^0.5 * (1 - (1 - θe^(1/m))^m)^2
    return K_θ
end

function darcy_law(K, ψ, Δz)
    q = zeros(eltype(ψ), length(ψ) - 1)
    for i in 1:length(q)
        K_avg = (K[i] + K[i + 1]) / 2
        q[i] = - K_avg * ((ψ[i + 1] - ψ[i])/ Δz + 1)
    end
    return q
end

function conservation_mass(θ, Δt, Δz, q)
    θ_new = copy(θ)
    for i in 2:(length(θ)-1)
        θ_new[i] = θ[i] + (Δt/Δz) * (q[i-1] - q[i])
    end
    return θ_new
end

function boundary_conditions(p_rate, K, θ, θ_new, Δt, Δz, q, soil_p)
    θ_new[1] = θ_new[1] + (Δt/Δz) * (p_rate - q[1])
    θ_new[end] = θ[end] + (Δt/Δz) * (K[end])

    θ_new = clamp.(θ_new, soil_p.θr + 0.001, soil_p.θs - 0.001)

    return θ_new
end

function richards_1d_step_explicit(θ, Δt, Δz, soil_p, p_rate)
    n = length(θ)
    ψ = θ_to_ψ(θ, soil_p)

    K = hydraulic_conductivity(θ, soil_p)

    q = darcy_law(K, ψ, Δz)

    θ_new = copy(θ)
    
    # Top, rainfall
    flux_in = p_rate
    flux_out = q[1]
    θ_new[1] = θ[1] + (Δt/Δz) * (flux_in - flux_out)
    
    # Interior conservation 
    for i in 2:(n-1)
        flux_in = q[i-1]
        flux_out = q[i]
        # θ_new[i] = θ[i] + (Δt/Δz) * (flux_in - flux_out) # old 
        θ_new[i] = θ[i] + (Δt/Δz) * (q[i-1] - q[i]) + 
           0.01 * (θ[i-1] - 2*θ[i] + θ[i+1])  # Smoothing term
    end
    
    # Bottom, gravity 
    flux_in = q[n-1]
    flux_out = K[n]  # Gravity drainage
    θ_new[n] = θ[n] + (Δt/Δz) * (flux_in - flux_out)
    
    # Physical bounds
    θ_new = clamp.(θ_new, soil_p.θr + 0.001, soil_p.θs - 0.001) # (x, lo, hi)
    return θ_new
end

function sim_explicit(n_steps, Δt, n_nodes, Δz, start_moisture, rain_time, p_rate)
    # soil_p = (θr=0.05, θs=0.45, α=3.6, n=2.0, m=0.5, K_sat=1e-3)
    soil_p = (θr=0.078, θs=0.43, α=3.6, n=1.56, m=0.359, K_sat=2.9e-5)

    rainfall_time = rain_time * n_steps
    θ = fill(start_moisture, n_nodes)
    θ_history = []

    println("Running Explicit Method: ")
    println("   Total simulation time: ", Δt * n_steps, "s")
    println("   Total domain depth:    ", Δz * n_nodes, " m")
    println("   Rainfall duration:     ", Δt * rainfall_time, " s")
    println("   Ranfall rate:          ", p_rate * 3600000, " mm/hr")
    
    for step in 1:n_steps
        if step == n_steps/2
            println(step/n_steps * 100, "% done.")
        end
        if step > rainfall_time # rain half the time
            p_rate = 0.0
        end
        θ = richards_1d_step_explicit(θ, Δt, Δz, soil_p, p_rate)
        push!(θ_history, copy(θ))
    end
     
    # plot
    θ_hist = hcat(θ_history...)
    heatmap(θ_hist', 
    xlabel="Depth", 
    ylabel="Time",
    title="Explicit Richards Sim",
    color=:blues,
    clim=(0.30, 0.35),
    yflip=true)
end

function residual(θ_guess, θ, Δz, Δt, soil_p, p_rate)
    ψ = θ_to_ψ(θ_guess, soil_p)
    K = hydraulic_conductivity(θ_guess, soil_p)
    q = darcy_law(K, ψ, Δz)
    θ_new = similar(θ_guess)
    θ_new .= θ
    θ_new[1] = θ[1] + (Δt/Δz) * (p_rate - q[1])
    for i in 2:(length(θ) - 1)
        θ_new[i] = θ[i] + (Δt/Δz) * (q[i-1] - q[i]) + 
            0.01 * (θ[i-1] - 2*θ[i] + θ[i+1]) # smoothing term
    end
    θ_new[end] = θ[end] + (Δt/Δz) * (q[end-1] - K[end])
    R = θ_guess - θ_new

    return R
end

function richards_1d_step_implicit(θ, Δt, Δz, soil_p, p_rate, max_calls)
    # θ_guess = richards_1d_step_explicit(θ, Δt, Δz, soil_p, p_rate)
    θ_guess = 0.90 * θ + 0.10 * richards_1d_step_explicit(θ, Δt, Δz, soil_p, p_rate) # weighted avg
    cur_Δt = Δt
    for attempt in 1:5
        params = (θ=θ, Δz=Δz, cur_Δt=cur_Δt, soil_p=soil_p, p_rate=p_rate)
        function residual_func(θ_guess, p)
            return residual(θ_guess, p.θ, p.Δz, p.cur_Δt, p.soil_p, p.p_rate)
        end
        nl_prob = NonlinearProblem(residual_func, θ_guess, params)
        sol = solve(nl_prob, NewtonRaphson(),reltol = 1e-4, abstol = 1e-6, maxiters=20)
        if sol.retcode == ReturnCode.Success
            θ_new = sol.u
        return clamp.(θ_new, soil_p.θr + 0.001, soil_p.θs - 0.001), true
        else
            cur_Δt = cur_Δt / 2
        end
    end
    return θ_guess, false
end

function sim_implicit(n_steps, Δt, n_nodes, Δz, start_moisture, rain_time, p_rate)
    soil_p = (θr=0.078, θs=0.43, α=3.6, n=1.56, m=0.359, K_sat=2.9e-5)
    θ = fill(start_moisture, n_nodes) 
    rainfall_time = rain_time * n_steps
    θ_history = []
    count = 0
    println("Running Implicit Method: ")
    println("   Total simulation time: ", Δt * n_steps, "s")
    println("   Total domain depth:    ", Δz * n_nodes, " m")
    println("   Rainfall duration:     ", Δt * rainfall_time, " s")
    println("   Ranfall rate:          ", p_rate * 3600000, " mm/hr")

    for step in 1:n_steps
        if step == n_steps/2
            println(step/n_steps * 100, "% done.")
        end
        if step > rainfall_time
            p_rate = 0.0
        end
        θ, method = richards_1d_step_implicit(θ, Δt, Δz, soil_p, p_rate, 5) # true for implicit, false for explicit
        count += method
        push!(θ_history, copy(θ))
    end
    println("number of times used implicit: ", count, " / ", n_steps)
    # plot
    θ_hist = hcat(θ_history...)
    heatmap(θ_hist', 
    xlabel="Depth", 
    ylabel="Time",
    title="Implicit Richards Sim",
    color=:blues,
    clim=(0.30, 0.35),
    yflip=true)
end

# Run 
# sim_explicit(n_steps, Δt, n_nodes, Δz, start_moisture, rain_time, p_rate)
# @time sim_explicit(100000, 0.001, 100, 0.01, 0.29, 1/2, 1e-5)
# @time sim_implicit(10000, 0.01, 100, 0.01, 0.29, 1/2, 1e-5)

"""
Light rain: p_rate = 1e-6 m/s (3.6 mm/hr)
Heavy rain: p_rate = 1e-5 m/s (36 mm/hr)
Storm event: p_rate = 3e-5 m/s (108 mm/hr)
"""

