"""
    list_station_files(station_dir::AbstractString) -> Vector{String}

Return absolute paths of `.stm` files in `station_dir`.

# Example
```julia
files = list_station_files("data/stations")
first(files, 3)
"""
function list_station_files(station_dir::AbstractString)::Vector{String}
    return [p for p in readdir(station_dir; join=true) if isfile(p) && endswith(p, ".stm")]
end

"""
    var_depth_tokens(filenames::AbstractVector{<:AbstractString}) -> Vector{String}

Extract `<var>_<depth>` tokens from station filenames like:

    <network>_<station>_<site>_<var>_<depth1>_<depth2>_<sensor>_<start>_<end>.stm

where `<var>` ∈ {`sm`, `p`, `ts`, `ta`} and `<depth*>` are signed numbers.  
Non-matching files are skipped; tokens are truncated to 8 chars.

# Example
```julia
files = ["..._sm_0.050000_...", "..._sm_0.200000_...", "readme.txt"]
var_depth_tokens(files)
# -> ["sm_0.050", "sm_0.200"]
"""
function var_depth_tokens(filenames::AbstractVector{<:AbstractString})::Vector{String}
    var_depth = String[]
    for f in filenames
        parts = split(basename(f), "_")
        if length(parts) >= 5
            var, depth1 = parts[4], parts[5]
            depth_tmp = parse(Float64, depth1)
            if round(Int, depth_tmp) != 0
                name = string(var, "_", string(round(Int, depth_tmp)), "_000")
            else
                col_name = string(var, "_", @sprintf("%.3f", parse(Float64, depth1)))
                name = col_name[1:3] * col_name[6:end]
                name[end-2:end] == "000" ? name = name[1:end-3] * "_050" : nothing
            end
            push!(var_depth, name)
        end
    end
    return var_depth
end

"""
    read_stm(file_path::String)::DataFrame

Read one CAT-XMS `.stm` file and return a tidy table with `:timestamp` and `:theta`.

- Expects space-delimited, no header; skips first data row (metadata).
- Builds `:timestamp` from `date_str time_str` (`yyyy/mm/dd HH:MM`).
- Parses `:theta` as `Float64` (unparsable → `NaN`); sorts by `:timestamp`.

# Arguments
- `file_path::String`: path to the file.

# Returns
- `DataFrame` with columns `:timestamp::DateTime`, `:theta::Float64`.
"""
function read_stm(file_path::String)::DataFrame
    df = CSV.read(file_path, DataFrame; 
                    # skipto=2,
                    delim = ' ', 
                    ignorerepeated = true, 
                    ignoreemptyrows=true,
                    comment = "#",
                    header = false, 
                    select=1:5, 
                    silencewarnings=true) # reads in metadata then thinks there are 9 columns
    rename!(df, [:date_str, :time_str, :theta, :qflag, :srcflag])
    deleteat!(df,1)
    fmt = dateformat"yyyy/mm/dd HH:MM"
    ts  = strip.(string.(df.date_str, " ", df.time_str))
    bad_ix = findall(t -> (try; DateTime(t, fmt); false; catch; true; end), ts)

    # println(bad_ix) # drop bad timestamp rows
    deleteat!(df, bad_ix)
    df.timestamp = DateTime.(string.(df.date_str, " ", df.time_str), dateformat"yyyy/mm/dd HH:MM")
    df.theta = coalesce.(parse.(Float64, df.theta), NaN)
    # df.theta = coalesce.(x -> x isa AbstractString ? parse(Float64, x) : Float64(x), df.theta, NaN)
    sort!(df, :timestamp)
    return select(df, [:timestamp, :theta]) 
end

"""
   merge_station_data(files::Vector{AbstractString}, col_names::Vector{AbstractString})::DataFrame

Read multiple CAT-XMS files, rename each `:theta` column to `col_names[i]`,
and **outer-join** them on `:timestamp` into a single table.

- Skips entries where `col_names[i] === nothing`.
- Sorts and deduplicates by `:timestamp`.

# Arguments
- `files::Vector{AbstractString}`: paths to `.stm` files (same order as `col_names`).
- `col_names::Vector{AbstractString}`: desired column names per file (use `nothing` to skip).

# Returns
- `DataFrame` with `:timestamp` and one column per kept file.
"""
function merge_station_data(files::AbstractVector{<:AbstractString}, col_names::AbstractVector{<:AbstractString})::DataFrame
    f1 = files[1]
    df = read_stm(f1)
    rename!(df, :theta=> col_names[1])
    for (k, file_name) in enumerate(files[2:end])
        # println(k, files[k] * " " * col_names[k])
        d = read_stm(file_name)
        rename!(d, :theta => col_names[k + 1])
        df = outerjoin(df, d, on=:timestamp, makeunique = true)
    end
    sort!(df, :timestamp)
    unique!(df, :timestamp)
    return df
end

function soil_params(soil_type::String)
    param_dict = Dict(
        "sand" => (θr=0.045, θs=0.43, α=14.5, n=2.68, m=0.627, K_sat=5.8e-5),
        "loam" => (θr=0.078, θs=0.43, α=3.6, n=1.56, m=0.359, K_sat= 2.9e-6),
        "clay" => (θr=0.068, θs=0.38, α=0.8, n=1.09, m=0.083, K_sat=5.6e-7),
        "silt" => (θr=0.034, θs=0.46, α=1.6, n=1.37, m=0.270, K_sat=6.9e-7)
    )
    if haskey(param_dict, lowercase(soil_type))
        return param_dict[lowercase(soil_type)]
    else
        error("Unknown soil type: $soil_type. Available: $(keys(param_dict))")
    end
end

"""
    load_station_data(station_dir::AbstractString) -> DataFrame

Load all `.stm` files in `station_dir` and return a single table joined on `:timestamp`.

Internally calls:
- `read_station_filenames` to list files,
- `extract_variable_depth` to derive column names,
- `gather_data` to read and outer-join.

# Arguments
- `station_dir`: directory containing station `.stm` files.

# Returns
- `DataFrame` with `:timestamp` and one column per file.
"""
function load_station_data(station_dir::AbstractString)::DataFrame
    isdir(station_dir) || throw(ArgumentError("Not a directory: $station_dir"))
    filenames = list_station_files(station_dir)
    col_names = var_depth_tokens(filenames)
    # print(filenames, col_names)
    df = merge_station_data(filenames, col_names)
    return df
end

function avg_sm!(df::DataFrame)
    # df[!, :avg_sm] = mean.(eachrow(df[!, [:"sm_0.050", :"sm_0.200", :"sm_0.500", :"sm_1.000"]]))
    cols = names(df, r"^sm")
    df[!, :avg_sm] = sum.(eachrow(df[!, cols])) ./ length(cols)
end

function avg_ts!(df::DataFrame)
    cols = names(df, r"^ts")
    if isempty(cols)
        return nothing
    end
    df[!, :avg_ts] = sum.(eachrow(df[!, cols])) ./ length(cols)
end

function sm_grad!(df::DataFrame)
    cols = names(df, r"^sm")
    col_values = Any[match(r"(-?\d+)_?(\d*)$", name) for name in cols]
    for i in eachindex(col_values)
        whole, frac = col_values[i].captures
        digits = whole * frac
        col_values[i] = parse(Int, digits) / 1000
    end
    for i in 1:length(col_values)-1
        col_name = string("grad_", col_values[i], "_", col_values[i+1])
        df[!, Symbol(col_name)] = (df[!,cols[i]] - df[!,cols[i+1]]) / (col_values[i] - col_values[i+1])
    end
end

function clean!(df)
    # trim sm, ts, ta, p, within realistic bounds 
    bounds = Dict(
        "sm" => (0, 0.6),
        "ts" => (-10, 60),
        "ta" => (-40, 100),
        "p" => (0, 200)
    )
    for col in names(df)
        for (prefix, (low, high)) in bounds
            if startswith(col, prefix)
                df[!, col] = ifelse.(
                    ismissing.(df[!, col]) .| (df[!, col] .< low) .| (df[!, col] .> high),
                    missing,
                    df[!, col],
                )
            end
        end
    end
end

function handle_missing!(df)
    dropmissing!(df)
    return df
end

function preprocess(station_dir::AbstractString)
    df = load_station_data(station_dir)
    clean!(df)
    handle_missing!(df)
    avg_sm!(df)
    avg_ts!(df)
    sm_grad!(df)
    return df
end

function load_station_names(basepath="data")
    station_names = String[]
    for network in filter(isdir, readdir(basepath; join=true))
        for station in filter(isdir, readdir(network; join=true))
            push!(station_names, station)
        end
    end
    return station_names
end

function load_all_stations()
    station_names = load_station_names()
    station_data = Dict()
    for s in station_names
        station_data[s] = preprocess(s)
    end
    return station_data
end

# Example usage:
# station_dir = "data/XMS-CAT/Pessonada"
# df = preprocess(station_dir)
# station_names = load_station_names()
# all_station_data = load_all_stations()