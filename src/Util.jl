module Util

using Revise, Nullables

"""
    add_quotes(str::String) :: String

Adds quotes around `str` and escapes any previously existing quotes.
"""
function add_quotes(str::String) :: String
  if ! startswith(str, "\"")
    str = "\"$str"
  end
  if ! endswith(str, "\"")
    str = "$str\""
  end

  str
end


"""
    strip_quotes(str::String) :: String

Unquotes `str`.
"""
function strip_quotes(str::String) :: String
  if is_quoted(str)
    str[2:end-1]
  else
    str
  end
end


"""
    is_quoted(str::String) :: Bool

Checks weather or not `str` is quoted.
"""
function is_quoted(str::String) :: Bool
  startswith(str, "\"") && endswith(str, "\"")
end


"""
    function walk_dir(dir, paths = String[]; only_extensions = ["jl"], only_files = true, only_dirs = false) :: Vector{String}

Recursively walks dir and `produce`s non directories. If `only_files`, directories will be skipped. If `only_dirs`, files will be skipped.
"""
function walk_dir(dir, paths = String[]; only_extensions = ["jl"], only_files = true, only_dirs = false) :: Vector{String}
  f = readdir(abspath(dir))
  for i in f
    full_path = joinpath(dir, i)
    if isdir(full_path)
      ! only_files || only_dirs && push!(paths, full_path)
      walk_dir(full_path, paths)
    else
      only_dirs && continue

      (last(split(i, ['.'])) in only_extensions) || isempty(only_extensions) && push!(paths, full_path)
    end
  end

  paths
end


"""
    expand_nullable{T}(value::Nullable{T}, default::T) :: T

Returns `value` if it is not `null` - otherwise `default`.
"""
function expand_nullable(value::T)::T where T
  value
end
function expand_nullable(value::Nullable{T}, default::T)::T where T
  if isnull(value)
    default
  else
    Base.get(value)
  end
end

end
