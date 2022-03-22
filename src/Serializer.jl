module Serializer

import SearchLight

function serialize end

function deserialize end

function serializables end # return Vector{Symbol}

include("../serializers/JsonSerializer.jl")

end