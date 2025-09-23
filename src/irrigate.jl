
# take station data and plot when to irrigate based on crop type
const CROPS = Dict(
    "shallow" => (depth=0.3, θ_crit=0.15, θ_fc=0.35, mad=0.4, name="Lettuce/Grass"),
    "medium" => (depth=0.6, θ_crit=0.12, θ_fc=0.35, mad=0.5, name="Tomato/Pepper"),
    "deep" => (depth=1.0, θ_crit=0.10, θ_fc=0.35, mad=0.6, name="Corn/Tree")
)

