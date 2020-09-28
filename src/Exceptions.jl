module Exceptions

using SearchLight

export NotPersistedException, MissingDatabaseConfigurationException, DatabaseAdapterException
export UnretrievedModelException, InvalidModelException

struct NotPersistedException <: Exception
  model
end

Base.showerror(io::IO, ex::NotPersistedException) = print(io, "NotPersistedException: Model is not persisted \n$(ex.model)")


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


struct UnretrievedModelException <: Exception
  model
  id
end

Base.showerror(io::IO, ex::UnretrievedModelException) = print(io, "UnretrievedModelException: Model can not be retrieved for id $(ex.id)")


struct InvalidModelException <: Exception
  model
  errors
end

Base.showerror(io::IO, ex::InvalidModelException) =
  print(io, "Validation errors for $(typeof(ex.model)): $(join( map(e -> "$(e.field) $(e.error_message)", ex.errors), ", "))")

end