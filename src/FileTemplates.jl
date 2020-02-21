"""
Functionality for handling the default content of the various files (migrations, models, controllers, etc).
"""
module FileTemplates

using SearchLight


"""
    new_database_migration(module_name::String) :: String

Default content for a new SearchLight migration.
"""
function new_table_migration(module_name::String, resource::String) :: String
  """
  module $module_name

  import SearchLight.Migrations: create_table, column, primary_key, add_index, drop_table

  function up()
    create_table(:$resource) do
      [
        primary_key()
        column(:column_name, :column_type)
      ]
    end

    add_index(:$resource, :column_name)
  end

  function down()
    drop_table(:$resource)
  end

  end
  """
end


function newmigration(module_name::String) :: String
  """
  module $module_name

  import SearchLight.Migrations: add_column, add_index

  function up()

  end

  function down()

  end

  end
  """
end


"""
    newmodel(model_name::String, resource_name::String = model_name) :: String

Default content for a new SearchLight model.
"""
function newmodel(model_name::String, resource_name::String = model_name; pluralize::Bool = true) :: String
  """
  module $(SearchLight.Inflector.to_plural(model_name))

  import SearchLight: AbstractModel, DbId
  import Base: @kwdef

  export $model_name

  @kwdef mutable struct $model_name <: AbstractModel
    id::DbId = DbId()
  end

  end
  """
end


"""
    newvalidator(validator_name::String) :: String

Default content for a new SearchLight validator.
"""
function newvalidator(validator_name::String; pluralize::Bool = true) :: String
  """
  module $(SearchLight.Inflector.to_plural(validator_name))Validator

  using SearchLight, SearchLight.Validation

  function not_empty(field::Symbol, m::T, args::Vararg{Any})::ValidationResult where {T<:AbstractModel}
    isempty(getfield(m, field)) && return ValidationResult(invalid, :not_empty, "should not be empty")

    ValidationResult(valid)
  end

  end
  """
end


function adapter_default_config end


function newconfig() :: String
  """
  env: $(SearchLight.config.app_env)

  $(adapter_default_config())
    config:
      log_queries: true
      log_level: :debug
  """
end


"""
    newtest(resource_name::String) :: String

Default content for a new test file.
"""
function newtest(resource_name::String) :: String
  """
  using Test, SearchLight, $resource_name

  @testset "$resource_name unit tests" begin

    ### Your tests here
    @test 1 == 1

  end;
  """
end

end