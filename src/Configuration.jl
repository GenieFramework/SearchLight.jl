"""
Core SearchLight configuration / settings functionality.
"""
module Configuration

import Revise
import YAML, Logging
using SearchLight

export env, Settings
# app environments
const DEV   = "dev"
const PROD  = "prod"
const TEST  = "test"

haskey(ENV, "SEARCHLIGHT_ENV") || (ENV["SEARCHLIGHT_ENV"] = DEV)


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
  endswith(db_settings_file, ".yml") || throw("Unknow configuration file type - expecting .yml")
  db_conn_data::Dict =  YAML.load(open(db_settings_file))

  if  haskey(db_conn_data, "env") && db_conn_data["env"] !== nothing
    ENV["SEARCHLIGHT_ENV"] =  if strip(uppercase(string(db_conn_data["env"]))) == """ENV["GENIE_ENV"]"""
                                ENV["GENIE_ENV"]
                              else
                                db_conn_data["env"]
                              end

    SearchLight.config.app_env = ENV["SEARCHLIGHT_ENV"]
  end

  if  haskey(db_conn_data, SearchLight.config.app_env)
      if haskey(db_conn_data[SearchLight.config.app_env], "config") && isa(db_conn_data[SearchLight.config.app_env]["config"], Dict)
        for (k, v) in db_conn_data[SearchLight.config.app_env]["config"]
          if k == "log_level"
            for dl in Dict("debug" => Logging.Debug, "error" => Logging.Error, "info" => Logging.Info, "warn" => Logging.Warn)
              occursin(dl[1], v) && setfield!(SearchLight.config, Symbol(k), dl[2])
            end
          else
            setfield!(SearchLight.config, Symbol(k), ((isa(v, String) && startswith(v, ":")) ? Symbol(v[2:end]) : v) )
          end
        end
      end

      if ! haskey(db_conn_data[SearchLight.config.app_env], "options") || ! isa(db_conn_data[SearchLight.config.app_env]["options"], Dict)
        db_conn_data[SearchLight.config.app_env]["options"] = Dict{String,String}()
      end
  end

  haskey(db_conn_data, SearchLight.config.app_env) ?
    db_conn_data[SearchLight.config.app_env] :
    throw(SearchLight.MissingDatabaseConfigurationException("DB configuration for $(SearchLight.config.app_env) not found"))
end


function load(path::Union{String,Nothing} = nothing) :: Dict{String,Any}
  db_config_file = path === nothing ? joinpath(SearchLight.DB_PATH, SearchLight.SEARCHLIGHT_DB_CONFIG_FILE_NAME) : path
  SearchLight.config.db_config_settings = read_db_connection_data(db_config_file)
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

  log_queries::Bool
  log_level::Logging.LogLevel
  log_to_file::Bool

  Settings(;
            app_env       = ENV["SEARCHLIGHT_ENV"],

            db_migrations_table_name  = SearchLight.SEARCHLIGHT_MIGRATIONS_TABLE_NAME,
            db_migrations_folder      = SearchLight.MIGRATIONS_PATH,
            db_config_settings        = Dict{String,Any}(),

            log_queries   = true,
            log_level     = Logging.Debug,
            log_to_file   = true
        ) =
              new(
                  app_env,
                  db_migrations_table_name, db_migrations_folder, db_config_settings,
                  log_queries, log_level, log_to_file
                )
end

end
