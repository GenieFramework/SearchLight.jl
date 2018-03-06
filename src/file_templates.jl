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

  import Migration: create_table, column, column_id, add_index, drop_table

  function up()
    create_table(:table_name) do
      [
        column_id()
        column(:column_name, :column_type, options)
      ]
    end

    add_index(:table_name, :column_name, options)
  end

  function down()
    drop_table(:table_name)
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
  module $pluralized_name

  using SearchLight #, $(Inflector.to_plural(model_name) |> Base.get)Validator

  export $model_name

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
        # (:title, $(Inflector.to_plural(model_name) |> Base.get)Validator.not_empty)
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
            id
            # validator,
            # belongs_to, has_one, has_many,
            # before_save, after_save, on_dehydration, on_hydration, after_hydration
            # scopes
            )
  end

  end
  """
end


"""
    new_validator(validator_name::String) :: String

Default content for a new SearchLight validator.
"""
function new_validator(validator_name::String) :: String
  """
  module $(Inflector.to_plural(validator_name) |> Base.get)Validator

  using SearchLight, Validation

  function not_empty{T<:AbstractModel}(field::Symbol, m::T, args::Vararg{Any}) :: ValidationResult
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
    filename: db/dev.sqlite3
  """


  """
  env: dev

  $(adapters[adapter])
    config:
      suppress_output: false
      output_length: 10000
      log_db: true
      log_queries: true
      log_level: :debug
  """
end


"""
    new_test(plural_name::String, singular_name::String) :: String

Default content for a new test file.
"""
function new_test(plural_name::String, singular_name::String) :: String
  """
  using SearchLight, $(plural_name)

  ### Your tests here
  @test 1 == 1
  """
end


end
