module JsonSerializer

using JSON

using SearchLight
using SearchLight.Serializer

function SearchLight.Serializer.serialize(value) :: String
  JSON.json(value)
end

function SearchLight.Serializer.deserialize(::Type{T}, value; dicttype = Dict)::T where {T}
  JSON.parse(value, T; dicttype)
end

end