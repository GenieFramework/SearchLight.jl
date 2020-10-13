module Exceptions

using SearchLight

export NotPersistedException, MissingDatabaseConfigurationException, DatabaseAdapterException
export UnretrievedModelException, InvalidModelException

abstract type SearchLightException <: Exception end

Base.showerror(io::IO, ex::T) where {T<:SearchLightException} = print(io, ex.msg)

struct NotPersistedException <: Exception
  model
  msg
end
NotPersistedException(model) = NotPersistedException(model, "NotPersistedException: Model is not persisted \n$model")


struct MissingDatabaseConfigurationException <: Exception
  msg::String
end
MissingDatabaseConfigurationException() = MissingDatabaseConfigurationException("The database configuration can not be found")


struct NotConnectedException <: Exception
  msg::String
end
NotConnectedException() = NotConnectedException("SearchLight is not connected to the database")


struct DatabaseAdapterException <: Exception
  msg::String
end
DatabaseAdapterException() = DatabaseAdapterException("The SearchLight database adapter has thrown an unexpected exception")


struct UnretrievedModelException <: Exception
  model
  id
  msg
end
UnretrievedModelException(model, id) = UnretrievedModelException(model, id, "UnretrievedModelException: the $(typeof(model)) data could not be retrieved for id $id. \nModel: \n$model")


struct InvalidModelException <: Exception
  model
  errors
  msg
end
InvalidModelException(model, errors) = InvalidModelException("The $(typeof(model)) model has validation errors:\n$errors")

end