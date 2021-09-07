module Callbacks


# specialized to be automatically invoked when a model exception is triggered internally
# accepts (model <: AbstractModel, ex::TypeConversionException)
# returns model <: AbstractModel
function on_exception end


# specialize to be automatically invoked when model data is retrieved from the DB (on `find` methods)
# it will be invoked for each field in the model
# accepts (model <: AbstractModel, field_name::Symbol, value::Any)
# returns model <: AbstractModel
function on_find end


# specialize to be automatically invoked after the object is retrieved from the DB
# accepts (model <: AbstractModel)
# return model <: AbstractModel
function after_find end


# specialize to be automatically invoked when the object is being peristed to the DB
# accepts (model <: AbstractModel, field_name::Symbol, value::Any)
# returns model <: AbstractModel
function on_save end


# specialize to be automatically invoked before the object is being peristed to the DB
# accepts (model <: AbstractModel)
# returns model <: AbstractModel
function before_save end


# specialize to be automatically invoked after the object is being peristed to the DB
# accepts (model <: AbstractModel)
# returns model <: AbstractModel
function after_save end

end