module Foos

import SearchLight: AbstractModel, DbId
import Base: @kwdef

export Foo

@kwdef mutable struct Foo <: AbstractModel
  id::DbId = DbId()
end

end
