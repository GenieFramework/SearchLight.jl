"""
Functionality for handling the default content of the various files (migrations, models, controllers, etc).
"""
module FileTemplates

using SearchLight, SearchLight.Inflector


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


"""
"""
function new_migration(module_name::String) :: String
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
  pluralized_name = SearchLight.Inflector.to_plural(model_name)
  table_name = SearchLight.Inflector.to_plural(resource_name) |> lowercase

  """
  module $pluralized_name

  using SearchLight

  export $model_name

  mutable struct $model_name <: AbstractModel
    ### INTERNALS
    _table_name::String
    _id::String

    ### FIELDS
    id::DbId

    ### constructor
    $model_name(;
      ### FIELDS
      id = DbId()
    ) = new("$table_name", "id",                                                 ### INTERNALS
            id                                                                   ### FIELDS
            )
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


function new_db_config(adapter::Symbol = :sqlite) :: String
  adapters = Dict{Symbol,String}()

  adapters[:mysql] = """
  dev:
    adapter:  MySQL
    database: yourdb
    host:     127.0.0.1
    username: root
    port:     3306
    password: ""
  """

  adapters[:postgres] = """
  dev:
    adapter:  PostgreSQL
    database: yourdb
    host:     127.0.0.1
    username: root
    port:     5432
    password: ""
  """

  adapters[:sqlite] = """
  dev:
    adapter:  SQLite
    filename: db/$(SearchLight.config.app_env).sqlite3
  """


  """
  env: ENV["GENIE_ENV"]

  $(adapters[adapter])
    config:
      log_db: true
      log_queries: true
      log_level: :debug
  """
end


"""
    newtest(plural_name::String, singular_name::String) :: String

Default content for a new test file.
"""
function newtest(plural_name::String, singular_name::String; pluralize::Bool = true) :: String
  """
  include(joinpath("..", "..", "$(SearchLight.SEARCHLIGHT_BOOTSTRAP_FILE_NAME)"))
  using Test

  ### Your tests here
  @test 1 == 1
  """
end


function new_app_loader(app_name::String)
  """
  module $app_name

  using Revise
  using SearchLight

  Core.eval(SearchLight, :(config.db_config_settings = SearchLight.Configuration.load_db_connection()))

  SearchLight.Database.setup_adapter()
  SearchLight.Database.connect()
  SearchLight.load_resources()

  end

  using Revise
  using SearchLight, SearchLight.QueryBuilder
  using .$app_name
  """
end


function new_app_bootstrap(app_name::String)
  """
  include("$app_name.jl")
  """
end


function new_app_info(app_name::String)
  """
  const __APP_NAME = "$app_name"
  const __APP_FILE = "$app_name.jl"
  """
end


end
