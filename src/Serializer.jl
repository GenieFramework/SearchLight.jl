module Serializer

import SearchLight

function serialize end

function deserialize end

function serializables(::T)::Vector{Symbol} where {T<:SearchLight.AbstractModel}
  Symbol[]
end

function serializables(::Any)::Vector{Symbol}
  Symbol[]
end

include("../serializers/JsonSerializer.jl")

end