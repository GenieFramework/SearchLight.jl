"""
Provides a set of callback functions that can be specialized to be automatically invoked when a model is being persisted
to the DB or retrieved from the DB.

The user should specialize any of the the `on_exception`, `on_find`, `after_find`, `on_save`, `before_save` and
`after_save` abstract functions, as needed.

# Example
```julia
@kwdef mutable struct License <: AbstractModel
  id::DbId = DbId()
  user_id::Int = 0
  tier::Symbol = :free
end

SearchLight.Callbacks.on_find(license::License, field::Symbol, value::Any) = begin
  if field == :tier
    license.tier = Symbol(value) # convert to symbol cause db returns string
  elseif field == :id
    license.id = DbId(value)
  else
    setfield!(license, field, value)
  end

  return license
end
```
"""
module Callbacks

"""
Automatically invoked callback when a model exception is triggered internally (ex type conversion exception)

* accepts (model <: AbstractModel, ex::TypeConversionException)
* returns model <: AbstractModel
"""
function on_exception end


"""
Automatically invoked when model data is retrieved from the DB (on `find` methods).
It will be invoked for each field in the model

* accepts (model <: AbstractModel, field_name::Symbol, value::Any)
* returns model <: AbstractModel
"""
function on_find end


"""
Automatically invoked after the object is retrieved from the DB

* accepts (model <: AbstractModel)
* return model <: AbstractModel
"""
function after_find end


"""
Automatically invoked when the object is being peristed to the DB

* accepts (model <: AbstractModel, field_name::Symbol, value::Any)
* returns model <: AbstractModel
"""
function on_save end


"""
Automatically invoked before the object is being peristed to the DB

* accepts (model <: AbstractModel)
* returns model <: AbstractModel
"""
function before_save end


"""
Automatically invoked after the object is being peristed to the DB

* accepts (model <: AbstractModel)
* returns model <: AbstractModel
"""
function after_save end

end