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
            push!(var_depth, string(var, "_", @sprintf("%.3f", parse(Float64, depth1))))
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

# Example usage:
# station_dir = "data/XMS-CAT/Pessonada"
# station_dir = "data/test_station"
# df = load_station_data(station_dir)e