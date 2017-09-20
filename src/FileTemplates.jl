"""
Functionality for handling the default content of the various files (migrations, models, controllers, etc).
"""
module FileTemplates

using Inflector


"""
    new_database_migration(module_name::String) :: String

Default content for a new SearchLight migration.
"""
function new_database_migration(module_name::String) :: String
  """
  module $module_name

  using SearchLight

  function up()
    # SearchLight.query("")
    error("Not implemented")
  end

  function down()
    # SearchLight.query("")
    error("Not implemented")
  end

  end
  """
end


"""
    new_model(model_name::String, resource_name::String = model_name) :: String

Default content for a new SearchLight model.
"""
function new_model(model_name::String, resource_name::String = model_name) :: String
  pluralized_name = Inflector.to_plural(model_name) |> Base.get
  table_name = Inflector.to_plural(resource_name) |> Base.get |> lowercase

  """
  export $model_name, $pluralized_name

  mutable struct $model_name <: AbstractModel
    ### internals
    _table_name::String
    _id::String

    ### fields
    id::Nullable{SearchLight.DbId}

    ### validator
    # validator::ModelValidator

    ### relations
    # belongs_to::Vector{SearchLight.SQLRelation}
    # has_one::Vector{SearchLight.SQLRelation}
    # has_many::Vector{SearchLight.SQLRelation}

    ### callbacks
    # before_save::Function
    # after_save::Function
    # on_dehydration::Function
    # on_hydration::Function
    # after_hydration::Function

    ### scopes
    # scopes::Dict{Symbol,Vector{SearchLight.SQLWhereEntity}}

    ### constructor
    $model_name(;
      id = Nullable{SearchLight.DbId}(),

      # validator = ModelValidator([
        # (:title, Validation.$(model_name)Validator.not_empty)
      # ]),

      # belongs_to = [],
      # has_one = [],
      # has_many = [],

      # before_save = (m::$model_name) -> warn("Not implemented"),
      # after_save = (m::$model_name) -> warn("Not implemented"),
      # on_dehydration = (m::$model_name, field::Symbol, value::Any) -> warn("Not implemented"),
      # on_hydration = (m::$model_name, field::Symbol, value::Any) -> warn("Not implemented")
      # after_hydration = (m::$model_name, field::Symbol, value::Any) -> warn("Not implemented")

      # scopes = Dict{Symbol,Vector{SearchLight.SQLWhereEntity}}()

    ) = new("$table_name", "id",
            id,
            validator
            # belongs_to, has_one, has_many,
            # before_save, after_save, on_dehydration, on_hydration, after_hydration
            # scopes
            )
  end

  module $pluralized_name
  end
  """
end


"""
    new_validator(validator_name::String) :: String

Default content for a new SearchLight validator.
"""
function new_validator(validator_name::String) :: String
  """
  module $(validator_name)Validator

  using SearchLight, Validation

  function not_empty{T<:AbstractModel}(field::Symbol, m::T, args::Vararg{Any})::Bool
    isempty(getfield(m, field)) && return false
    true
  end

  end
  """
end


end
