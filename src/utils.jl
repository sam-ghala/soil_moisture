# lets follow along the tutorials
# eq = Dt(θ(z,t)) ~ -v * Dz(θ(z, t)) # just water moving through soil, downward constant speed
# eq = Dt(θ(z,t)) ~ D * Dz(Dz(θ(z,t))) - v * Dz(θ(z,t)) # add diffusion to advection

# bcs = [
#     θ(z, 0) ~ 0.29 # initial moisture throughout profile
#     θ(0, t) ~ 0.35 # top wet surface
#     θ(1.0, t) ~ 0.29 # 1m bc at 0.29
# ]
# Pure diffusion from step function initial condition
# D = 1e-7 # diffusion coefficient 
# v = 1e-6 # downward velocity
# eq = Dt(θ(z, t)) ~ D * Dz(Dz(θ(z, t)))
########################################################################
# # # # # # # # # Adapted from NeuralPDE Tutorial # # # # # # # # # # # 
########################################################################
using NeuralPDE, Lux, Optimization, OptimizationOptimJL, LineSearches, Plots
using ModelingToolkit
using DomainSets
 
@parameters z t
@variables θ(..)
Dz = Differential(z)
Dt = Differential(t)

function D_moist(θ_val)
    D_dry = 1e-8 # slow diffusion when dry
    D_wet = 5e-7 # fast diffusion when Wet
    return D_dry + (D_wet - D_dry) * ((θ_val - 0.29) / (0.35 - 0.29))
end

eq = Dt(θ(z, t)) ~ Dz(D_moist(θ(z, t)) * Dz(θ(z, t)))

bcs = [
    θ(z, 0) ~ 0.29 + 0.06 * (z < 0.2)
    θ(0, t) ~ 0.35 * (t < 1800) + 0.29 * (t >= 1800)
    θ(1.0, t) ~ 0.29
]
# Add explicit data points to boundary conditions
data_points = [
    θ(0.1, 0.0) ~ 0.35,  # Force wet initial condition
    θ(0.3, 0.0) ~ 0.29,  # Force dry initial condition
    θ(0.1, 100.0) ~ 0.34, # Force some time evolution
    θ(0.3, 100.0) ~ 0.30,
]

bcs = vcat(bcs, data_points)
domains = [z ∈ (0.0, 1.0), t ∈ (0.0, 3600.0)] # 1 meter

dim = 2 # depth and time
chain = Chain(
    Dense(dim, 32, σ), 
    Dense(32,32, σ), 
    Dense(32, 1)) # 2 input, 2 hidden, 1 output, sigmoid activation

discretization = PhysicsInformedNN(
    chain, QuadratureTraining(;
        batch = 1000,
        abstol = 1e-4,
        reltol = 1e-4,
    )
)
@named pde_system = PDESystem(eq, bcs, domains, [z, t], θ(z, t))
prob = discretize(pde_system, discretization)

opt = LBFGS(linesearch=BackTracking())
res = solve(prob, opt, maxiters = 500)
phi = discretization.phi
# heatmap|
z_grid = 0.0:0.01:1.0
t_grid = 0.0:50.0:3600.0
u_predict = [first(phi([z, t], res.u)) for z in z_grid, t in t_grid]
heatmap(t_grid, z_grid, u_predict, yflip=true, color=:blues, xlabel="Time", ylabel="Depth")

# validation
function validate_sol()
    println("checks")
    # Check 1: Boundary conditions
    surface_moisture = first(phi([0.0, 1800.0], res.u))  # at surface, mid-time
    bottom_moisture = first(phi([1.0, 1800.0], res.u))   # at bottom, mid-time
    println("Surface moisture (should ≈ 0.35): ", round(surface_moisture, digits=3))
    println("Bottom moisture (should ≈ 0.29): ", round(bottom_moisture, digits=3))
    
    # Check 2: Physical bounds
    test_points = [(0.5, 1000.0), (0.2, 2000.0), (0.8, 500.0)]
    println("Moisture values at test points:")
    for (z_test, t_test) in test_points
        moisture = first(phi([z_test, t_test], res.u))
        println("  z=$z_test, t=$t_test: θ = $(round(moisture, digits=3))")
        if moisture < 0.25 || moisture > 0.4
            println("  ⚠️  Moisture outside reasonable bounds!")
        end
    end
    
    # Check 3: Monotonic behavior (water should move downward over time)
    initial_profile = [first(phi([z, 0.0], res.u)) for z in [0.1, 0.3, 0.5]]
    final_profile = [first(phi([z, 3600.0], res.u)) for z in [0.1, 0.3, 0.5]]
    println("Initial vs Final moisture at depths [0.1, 0.3, 0.5]:")
    println("  Initial: ", [round(x, digits=3) for x in initial_profile])
    println("  Final:   ", [round(x, digits=3) for x in final_profile])
    
    return surface_moisture, bottom_moisture
end

surface_val, bottom_val = validate_sol()

function physics_diagnostics()
    println("=== PHYSICS DIAGNOSTICS ===")
    
    # Test points throughout domain
    test_points = [
        (0.2, 500.0),   # Shallow, early time
        (0.5, 1000.0),  # Mid-depth, mid-time  
        (0.8, 2000.0),  # Deep, late time
    ]
    
    for (z_test, t_test) in test_points
        # Get solution and compute derivatives manually
        θ_val = first(phi([z_test, t_test], res.u))
        
        # Finite difference approximations for derivatives
        h = 1e-6
        θ_dz_plus = first(phi([z_test + h, t_test], res.u))
        θ_dz_minus = first(phi([z_test - h, t_test], res.u))
        θ_dt_plus = first(phi([z_test, t_test + h], res.u))
        θ_dt_minus = first(phi([z_test, t_test - h], res.u))
        
        # Compute derivatives
        dθ_dt = (θ_dt_plus - θ_dt_minus) / (2*h)
        dθ_dz = (θ_dz_plus - θ_dz_minus) / (2*h)
        
        # Second derivative
        θ_center = θ_val
        d2θ_dz2 = (θ_dz_plus - 2*θ_center + θ_dz_minus) / (h^2)
        
        # Check PDE residual: should be ∂θ/∂t - D*∂²θ/∂z² ≈ 0
        D_val = D_moist(θ_val)
        pde_residual = dθ_dt - D_val * d2θ_dz2
        
        println("Point (z=$z_test, t=$t_test):")
        println("  θ = $(round(θ_val, digits=4))")
        println("  D(θ) = $(round(D_val, sigdigits=3))")
        println("  ∂θ/∂t = $(round(dθ_dt, sigdigits=3))")
        println("  D*∂²θ/∂z² = $(round(D_val * d2θ_dz2, sigdigits=3))")
        println("  PDE residual = $(round(pde_residual, sigdigits=3))")
        
        if abs(pde_residual) > 1e-4
            println("  ⚠️  Large PDE residual - physics not satisfied!")
        end
        println()
    end
end

# Run after training
physics_diagnostics()


############ with gravity 


@parameters z t
@variables θ(..)
Dz = Differential(z)
Dt = Differential(t)
v = 1e-6 # downward velocity

function D_moist(θ_val)
    D_dry = 1e-8 # slow diffusion when dry
    D_wet = 5e-7 # fast diffusion when Wet
    return D_dry + (D_wet - D_dry) * ((θ_val - 0.29) / (0.35 - 0.29))
end

# eq = Dt(θ(z, t)) ~ Dz(K_simple(θ(z, t)) * Dz(θ(z, t))) - K_simple(θ(z, t)) * 1.0
eq = Dt(θ(z, t)) ~ Dz(D_moist(θ(z, t)) * Dz(θ(z, t)) - v * Dz(θ(z,t)))

bcs = [
    θ(z, 0) ~ 0.29 + 0.06 * (z < 0.2)
    θ(0, t) ~ 0.35 * (t < 1800) + 0.29 * (t >= 1800)
    θ(1.0, t) ~ 0.29
]
# Add explicit data points to boundary conditions
data_points = [
    θ(0.1, 0.0) ~ 0.35,  # Force wet initial condition
    θ(0.3, 0.0) ~ 0.29,  # Force dry initial condition
    θ(0.1, 100.0) ~ 0.34, # Force some time evolution
    θ(0.3, 100.0) ~ 0.30,
]

bcs = vcat(bcs, data_points)
domains = [z ∈ (0.0, 1.0), t ∈ (0.0, 3600.0)] # 1 meter

dim = 2 # depth and time
chain = Chain(
    Dense(dim, 32, σ), 
    Dense(32,32, σ), 
    Dense(32, 1)) # 2 input, 2 hidden, 1 output, sigmoid activation

discretization = PhysicsInformedNN(
    chain, QuadratureTraining(;
        batch = 1000,
        abstol = 1e-4,
        reltol = 1e-4,
    )
)
@named pde_system = PDESystem(eq, bcs, domains, [z, t], θ(z, t))
prob = discretize(pde_system, discretization)

opt = LBFGS(linesearch=BackTracking())
res = solve(prob, opt, maxiters = 500)
phi = discretization.phi
# heatmap|
z_grid = 0.0:0.01:1.0
t_grid = 0.0:50.0:3600.0
u_predict = [first(phi([z, t], res.u)) for z in z_grid, t in t_grid]
heatmap(t_grid, z_grid, u_predict, yflip=true, color=:blues, xlabel="Time", ylabel="Depth")

println(size(u_predict))
println(u_predict[5])
println(u_predict[20])
println(u_predict[50])
println(u_predict[100])

########## with K_simple

@parameters z t
@variables θ(..)
Dz = Differential(z)
Dt = Differential(t)
# v = 1e-6 # downward velocity
sim_duration = 3600.0 # seconds
rain_duration = (1/2) * sim_duration # rain for first 1/3
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
function D_moist(θ_val)
    D_dry = 1e-8 # slow diffusion when dry
    D_wet = 5e-7 # fast diffusion when Wet
    return D_dry + (D_wet - D_dry) * ((θ_val - 0.29) / (0.35 - 0.29))
end

eq = Dt(θ(z, t)) ~ Dz(K_simple(θ(z, t)) * Dz(θ(z, t))) - K_simple(θ(z, t)) * 1.0
# eq = Dt(θ(z, t)) ~ Dz(D_moist(θ(z, t)) * Dz(θ(z, t)) - v * Dz(θ(z,t)))

bcs = [ # could input current emasured moisture profile here to start model
    θ(z, 0) ~ 0.29 + 0.06 * (z < 0.2)
    θ(0, t) ~ 0.35 * (t < rain_duration) + 0.29 * (t >= rain_duration)
    θ(1.0, t) ~ 0.29
]
# Add explicit data points to boundary conditions
data_points = [
    θ(0.1, 0.0) ~ 0.35,  # Force wet initial condition
    θ(0.3, 0.0) ~ 0.29,  # Force dry initial condition
    θ(0.1, 100.0) ~ 0.34, # Force some time evolution
    θ(0.3, 100.0) ~ 0.30,
]

bcs = vcat(bcs, data_points)
domains = [z ∈ (0.0, 1.0), t ∈ (0.0, sim_duration)] # 1 meter

dim = 2 # depth and time
chain = Chain(
    Dense(dim, 32, σ), 
    Dense(32,32, σ), 
    Dense(32, 1)) # 2 input, 2 hidden, 1 output, sigmoid activation

discretization = PhysicsInformedNN(
    chain, QuadratureTraining(;
        batch = 1000,
        abstol = 1e-4,
        reltol = 1e-4,
    )
)
@named pde_system = PDESystem(eq, bcs, domains, [z, t], θ(z, t))
prob = discretize(pde_system, discretization)

opt = LBFGS(linesearch=BackTracking())
res = solve(prob, opt, maxiters = 500)
phi = discretization.phi
# heatmap|
z_grid = 0.0:0.01:1.0
t_grid = 0.0:50.0:3600.0
u_predict = [first(phi([z, t], res.u)) for z in z_grid, t in t_grid]
heatmap(t_grid, z_grid, u_predict, yflip=true, color=:blues, xlabel="Time", ylabel="Depth")

println(size(u_predict))
println(u_predict[5])
println(u_predict[20])
println(u_predict[50])
println(u_predict[100])




# ######## with rainfall as extra dimension 

# @parameters z t p
# @variables θ(..)
# Dz = Differential(z)
# Dt = Differential(t)
# Dp = Differential(p)
# v = 1e-6 # downward velocity
# function K_simple(θ_val)
#     K_dry = 1e-8
#     K_wet = 1e-5
#     return K_dry + (K_wet - K_dry) * ((θ_val - 0.29) / (0.35 - 0.29))^2
# end
# function ψ(θ_val)
#     θe = (θ_val - θr) / (θs - θr)
#     ψ = (1/α) * ((θe^(-1/m) - 1)^(1/n))
#     return ψ
# end
# function D_moist(θ_val)
#     D_dry = 1e-8 # slow diffusion when dry
#     D_wet = 5e-7 # fast diffusion when Wet
#     return D_dry + (D_wet - D_dry) * ((θ_val - 0.29) / (0.35 - 0.29))
# end

# eq = Dt(θ(z, t, p)) ~ Dz(K_simple(θ(z, t, p)) * Dz(θ(z, t, p))) - K_simple(θ(z, t, p)) * 1.0
# # eq = Dt(θ(z, t)) ~ Dz(D_moist(θ(z, t)) * Dz(θ(z, t)) - v * Dz(θ(z,t)))

# bcs = [ # could input current emasured moisture profile here to start model
#     θ(z, 0, p) ~ 0.29 + 0.06 * (z < 0.2) # ic
#     θ(0, t, p) ~ 0.29 + (p * 1e6) # surface
#     θ(1.0, t, p) ~ 0.29 # bottom bc
# ]
# # Add explicit data points to boundary conditions
# data_points = [
#     θ(0.1, 0.0, 0.35) ~ 0.35,  # Force wet initial condition
#     θ(0.3, 0.0, 0.35) ~ 0.29,  # Force dry initial condition
#     θ(0.1, 100.0, 0.35) ~ 0.34, # Force some time evolution
#     θ(0.3, 100.0, 0.35) ~ 0.30,
# ]

# bcs = vcat(bcs, data_points)
# domains = [z ∈ (0.0, 1.0), t ∈ (0.0, 3600.0), p ∈ (0.0, 1e-4)] # 1 meter

# dim = 3 # depth and time
# chain = Chain(
#     Dense(dim, 32, σ), 
#     Dense(32,32, σ), 
#     Dense(32, 1)) # 2 input, 2 hidden, 1 output, sigmoid activation

# discretization = PhysicsInformedNN(
#     chain, QuadratureTraining(;
#         batch = 1000,
#         abstol = 1e-4,
#         reltol = 1e-4,
#     )
# )
# @named pde_system = PDESystem(eq, bcs, domains, [z, t, p], θ(z, t, p))
# prob = discretize(pde_system, discretization)

# opt = LBFGS(linesearch=BackTracking())
# res = solve(prob, opt, maxiters = 500)
# phi = discretization.phi
# # heatmap|
# z_grid = 0.0:0.01:1.0
# t_grid = 0.0:50.0:3600.0
# u_predict = [first(phi([z, t, 0.35], res.u)) for z in z_grid, t in t_grid]
# heatmap(t_grid, z_grid, u_predict, yflip=true, color=:blues, xlabel="Time", ylabel="Depth")
