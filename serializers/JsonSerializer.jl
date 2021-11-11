module JsonSerializer

using JSON3

using SearchLight
using SearchLight.Serializer

function SearchLight.Serializer.serialize(value) :: String
  JSON3.write(value)
end

function SearchLight.Serializer.deserialize(::Type{T}, value)::T where {T}
  JSON3.read(value, T)
end

end