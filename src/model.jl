using Lux,
    Optimisers,
    Random,
    Printf,
    Statistics,
    MLUtils,
    OnlineStats,
    CairoMakie,
    Reactant,
    Enzyme

rng = Random.default_rng()
Random.seed!(rng, 42)

"""
Richards Equation
- - - - - - - - -
Soil Arguemnts: 
    Hydraulic conductivity function K(θ) or K(ψ)
    Soil water retention curve ψ(θ)
    Saturated hydraulic conductivity Ks 
    Saturated water content θs
    Residual water content θr
    Van Genuchten parameters: α, n, m
Inital Conditions:
    Water content or pressure
Boundary Conditions:
    Surface: rainfall, evaporation(PET?)
    Bottom: free drainage, water table, some other flux 
    Side: no flow? allow?
Geometry:
    Spatial Domain: Column, Profile, Volume
    Discreitization
    Time domain
Physical Params:
    Gravity
    Coordniate (z-axis)
"""