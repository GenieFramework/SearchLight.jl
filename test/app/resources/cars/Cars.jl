module Cars

using SearchLight
import Base: @kwdef

export Car

@kwdef mutable struct Car <: AbstractModel
  id::DbId        = DbId()
  make::String    = ""
  max_speed::Int  = 220
end

end