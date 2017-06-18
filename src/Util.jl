module Util

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

end
