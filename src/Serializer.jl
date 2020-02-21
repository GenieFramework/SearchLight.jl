module Serializer

import SearchLight

function serialize end

function deserialize end

function serializables(m::Type{T})::Vector{Symbol} where {T<:SearchLight.AbstractModel}
  Symbol[]
end

end