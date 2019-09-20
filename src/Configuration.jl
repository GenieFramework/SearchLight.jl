"""
Core SearchLight configuration / settings functionality.
"""
module Configuration

using SearchLight, YAML

export isdev, isprod, istest, env, Settings, DEV, PROD, TEST

# app environments
const DEV   = "dev"
const PROD  = "prod"
const TEST  = "test"

haskey(ENV, "SEARCHLIGHT_ENV") || (ENV["SEARCHLIGHT_ENV"] = DEV)


"""
    isdev()  :: Bool
    isprod() :: Bool
    istest() :: Bool

Set of utility functions that return whether or not the current environment is development, production or testing.

# Examples
```julia
julia> Configuration.isdev()
true

julia> Configuration.isprod()
false
```
"""
function isdev()::Bool
  SearchLight.config.app_env == DEV
end
function isprod()::Bool
  SearchLight.config.app_env == PROD
end
function istest()::Bool
  SearchLight.config.app_env == TEST
end


"""
    env() :: String

Returns the current environment.

# Examples
```julia
julia> Configuration.env()
"dev"
```
"""
env() :: String = SearchLight.config.app_env


"""
    read_db_connection_data(db_settings_file::String) :: Dict{Any,Any}

Attempts to read the database configuration file and returns the part corresponding to the current environment as a `Dict`.
Does not check if `db_settings_file` actually exists so it can throw errors.
If the database connection information for the current environment does not exist, it returns an empty `Dict`.

# Examples
```julia
julia> Configuration.read_db_connection_data(...)
Dict{Any,Any} with 6 entries:
  "host"     => "localhost"
  "password" => "..."
  "username" => "..."
  "port"     => 5432
  "database" => "..."
  "adapter"  => "PostgreSQL"
```
"""
function read_db_connection_data(db_settings_file::String) :: Dict{String,Any}
  db_conn_data::Dict =  if endswith(db_settings_file, ".yml")
                          open(db_settings_file) do io
                            YAML.load(io)
                          end
                        elseif endswith(db_settings_file, ".jl")
                          include(db_settings_file)
                        end

  if  haskey(db_conn_data, "env") && db_conn_data["env"] != nothing
    ENV["SEARCHLIGHT_ENV"] =  if db_conn_data["env"] == """ENV["GENIE_ENV"]"""
                                ENV["GENIE_ENV"]
                              else
                                db_conn_data["env"]
                              end

    SearchLight.config.app_env = ENV["SEARCHLIGHT_ENV"]
  end

  if  haskey(db_conn_data, SearchLight.config.app_env) && haskey(db_conn_data[SearchLight.config.app_env], "config") &&
      db_conn_data[SearchLight.config.app_env]["config"] != nothing && isa(db_conn_data[SearchLight.config.app_env]["config"], Dict)
    for (k, v) in db_conn_data[SearchLight.config.app_env]["config"]
      setfield!(SearchLight.config, Symbol(k), ((isa(v, String) && startswith(v, ":")) ? Symbol(v[2:end]) : v) )
    end
  end

  return  if haskey(db_conn_data, SearchLight.config.app_env)
            db_conn_data[SearchLight.config.app_env]
          else
            @error "DB configuration for $(SearchLight.config.app_env) not found"

            Dict{String,Any}()
          end
end


"""
    load_db_connection() :: Bool

Attempts to load the database configuration from file. Returns `true` if successful, otherwise `false`.
"""
function load_db_connection(path::Union{String,Nothing} = nothing) :: Dict{String,Any}
  load_db_connection_from_config(path)
end


function load_db_connection_from_config(path::Union{String,Nothing} = nothing) :: Dict{String,Any}
  db_config_file = path === nothing ? joinpath(SearchLight.DB_PATH, SearchLight.SEARCHLIGHT_DB_CONFIG_FILE_NAME) : path
  read_db_connection_data(db_config_file)
end


function load(path::Union{String,Nothing} = nothing) :: Dict{String,Any}
  SearchLight.config.db_config_settings = load_db_connection(path)
end


"""
    mutable struct Settings

App configuration - sets up the app's defaults. Individual options are overwritten in the corresponding environment file.
"""
mutable struct Settings
  app_env::String

  db_migrations_table_name::String
  db_migrations_folder::String
  db_config_settings::Dict{String,Any}

  log_db::Bool
  log_queries::Bool
  log_level::Symbol
  log_formatted::Bool
  log_to_file::Bool

  model_relations_eagerness::Symbol

  Settings(;
            app_env       = ENV["SEARCHLIGHT_ENV"],

            db_migrations_table_name  = SearchLight.SEARCHLIGHT_MIGRATIONS_TABLE_NAME,
            db_migrations_folder      = SearchLight.MIGRATIONS_PATH,
            db_config_settings        = Dict{String,Any}(),

            log_db        = false,
            log_queries   = true,
            log_level     = :debug,
            log_formatted = true,
            log_to_file   = true,

            model_relations_eagerness = :lazy
        ) =
              new(
                  app_env,
                  db_migrations_table_name, db_migrations_folder, db_config_settings,
                  log_db, log_queries, log_level, log_formatted, log_to_file,
                  model_relations_eagerness
                )
end

end
