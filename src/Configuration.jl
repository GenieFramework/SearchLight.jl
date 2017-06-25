module Configuration

mutable struct Settings
  log_db::Bool
  log_queries::Bool
  db_config_settings::Dict{String,Any}
  db_migrations_table_name::String
  suppress_output::Bool

  Settings(;
    log_db                    = true,
    log_queries               = true,
    db_config_settings        = Dict{String,Any}(),
    db_migrations_table_name  = "schema_migrations",
    suppress_output           = false,
  ) = new(log_db, log_queries, db_config_settings, db_migrations_table_name, suppress_output)
end

end
