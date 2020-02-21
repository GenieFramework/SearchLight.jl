module Serialization


mutable struct Serializable{T}
  val::T
end


function serialize end


function deserialize end

end