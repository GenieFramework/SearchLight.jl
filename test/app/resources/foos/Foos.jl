module Foos

using SearchLight

export Foo

mutable struct Foo <: AbstractModel
  ### INTERNALS
  _table_name::String
  _id::String

  ### FIELDS
  id::DbId

  ### constructor
  Foo(;
    ### FIELDS
    id = DbId()
  ) = new("foos", "id",                                                 ### INTERNALS
          id                                                                   ### FIELDS
          )
end

end
