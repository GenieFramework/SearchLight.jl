"""
Provides auto serialization and deserialization of AbstractModel objects properties.

The `serialize and `deserialize` functions are used to convert the object to a string and back to the Julia data, respectively.
These methods should be specialized by the serializer and are automatically invoked by the `SearchLight` DB persisting and
retrieval methods. See included `JsonSerializer` for an example.

The user should specialize the `serializables` function to return a Vector{Symbol} of the models' properties that
should be serialized.

# Example
```julia
@kwdef mutable struct Session <: AbstractModel
  id::DbId = DbId()
  user_id::Int = 0
  hash::String = randstring(32)
  origin::String = ""
  metadata::Dict = Dict()
  created_at::DateTime = now()
  updated_at::DateTime = now()
end

SearchLight.Serializer.serializables(Session) = [:metadata]
```
"""
module Serializer

import SearchLight

function serialize end

function deserialize end

function serializables end # return Vector{Symbol}

include("../serializers/JsonSerializer.jl")

end