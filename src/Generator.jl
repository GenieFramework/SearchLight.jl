"""
Generates various Genie files.
"""
module Generator

using Revise
using Unicode, Nullables
using SearchLight.Loggers, SearchLight.FileTemplates, SearchLight.Inflector, SearchLight.Configuration, SearchLight, SearchLight.Migration

import SearchLight.Loggers: log


"""
    new_model(cmd_args::Dict{String,Any}) :: Nothing

Generates a new SearchLight model file and persists it to the resources folder.
"""
function new_model(cmd_args::Dict{String,Any}) :: Nothing
  resource_name = uppercasefirst(cmd_args["model:new"])
  if Inflector.is_singular(resource_name)
    resource_name = Inflector.to_plural(resource_name) |> Base.get
  end

  resource_path = setup_resource_path(resource_name)
  mfn = model_file_name(resource_name)
  write_resource_file(resource_path, mfn, resource_name, :model) &&
    log("New model created at $(abspath(joinpath(resource_path, mfn)))")

  nothing
end
function new_model(resource_name::Union{String,Symbol}) :: Nothing
  new_resource(resource_name)
end


"""
    new_resource(resource_name::Union{String,Symbol}) :: Nothing

Generates all the files associated with a new resource and persists them to the resources folder.
"""
function new_resource(resource_name::Union{String,Symbol}) :: Nothing
  resource_name = string(resource_name)

  sf = Inflector.to_singular(resource_name)
  model_name = (isnull(sf) ? resource_name : Base.get(sf)) |> uppercasefirst
  new_model(Dict{String,Any}("model:new" => model_name))
  new_table_migration(Dict{String,Any}("migration:new" => resource_name))

  resource_name = uppercasefirst(resource_name)
  if Inflector.is_singular(resource_name)
    resource_name = Inflector.to_plural(resource_name) |> Base.get
  end

  resource_path = setup_resource_path(resource_name)
  for (resource_file, resource_type) in [(validator_file_name(resource_name), :validator)]
    write_resource_file(resource_path, resource_file, resource_name, resource_type) &&
      log("New $resource_type created at $(abspath(joinpath(resource_path, resource_file)))")
  end

  isdir(SearchLight.TEST_PATH_UNIT) || mkpath(SearchLight.TEST_PATH_UNIT)
  test_file = resource_name * SearchLight.TEST_FILE_IDENTIFIER |> lowercase
  write_resource_file(SearchLight.TEST_PATH_UNIT, test_file, resource_name, :test) &&
    log("New unit test created at $(abspath(joinpath(SearchLight.TEST_PATH_UNIT, test_file)))")

  try
    include(SearchLight.SEARCHLIGHT_INFO_FILE_NAME)
  catch ex

  end
  if isdefined(@__MODULE__, :__APP_FILE)
    open(__APP_FILE, "a") do f
      write(f, "\nusing $resource_name")
    end
  else
    log("Can't write to app info", :warn)
  end

  SearchLight.load_resources()

  nothing
end


"""
"""
function new_table_migration(cmd_args::Dict{String,Any}) :: Nothing
  resource_name = uppercasefirst(cmd_args["migration:new"])

  Inflector.is_singular(resource_name) && (resource_name = Inflector.to_plural(resource_name) |> Base.get)

  migration_name = "create_table_" * lowercase(resource_name)
  Migration.new_table(migration_name, lowercase(resource_name))

  nothing
end
function new_table_migration(migration_name::String) :: Nothing
  new_table_migration(Dict{String,Any}("migration:new" => migration_name))
end


function new_migration(cmd_args::Dict{String,Any}) :: Nothing
  migration_name = replace(uppercasefirst(cmd_args["migration:new"]) |> lowercase, " "=>"_")

  Migration.new(migration_name)

  nothing
end
function new_migration(migration_name::String) :: Nothing
  new_migration(Dict{String,Any}("migration:new" => migration_name))
end


"""
    setup_resource_path(resource_name::String) :: String

Computes and creates the directories structure needed to persist a new resource.
"""
function setup_resource_path(resource_name::String) :: String
  resources_dir = SearchLight.RESOURCES_PATH
  resource_path = joinpath(resources_dir, lowercase(resource_name))

  if ! isdir(resource_path)
    mkpath(resource_path)
    push!(LOAD_PATH, resource_path)
  end

  resource_path
end


"""
    write_resource_file(resource_path::String, file_name::String, resource_name::String) :: Bool

Generates all resouce files and persists them to disk.
"""
function write_resource_file(resource_path::String, file_name::String, resource_name::String, resource_type::Symbol) :: Bool
  resource_name = Base.get(Inflector.to_singular(resource_name)) |> Inflector.from_underscores

  try
    if resource_type == :model
      resource_does_not_exist(resource_path, file_name) || return true
      open(joinpath(resource_path, file_name), "w") do f
        write(f, SearchLight.FileTemplates.new_model(resource_name))
      end

    elseif resource_type == :validator
      resource_does_not_exist(resource_path, file_name) || return true
      open(joinpath(resource_path, file_name), "w") do f
        write(f, SearchLight.FileTemplates.new_validator(resource_name))
      end

    elseif resource_type == :test
      resource_does_not_exist(resource_path, file_name) || return true
      open(joinpath(resource_path, file_name), "w") do f
        write(f, SearchLight.FileTemplates.new_test(Base.get(Inflector.to_plural( Inflector.from_underscores(resource_name) )), resource_name))
      end

    else
      error("Not supported, $file_name")
    end
  catch ex
    log(ex, :err)
  end

  true
end


"""
"""
function new_db_config(app_name::String = "App", adapter::Symbol = :mysql; create_folder::Bool = true, folder_name = lowercase(app_name)) :: Nothing
  if create_folder
    mkdir(folder_name)
    cd(folder_name)
  end

  isdir(SearchLight.CONFIG_PATH) || mkpath(SearchLight.CONFIG_PATH)
  isdir(SearchLight.APP_PATH) || mkpath(SearchLight.APP_PATH)
  isdir(SearchLight.config.db_migrations_folder) || mkpath(SearchLight.config.db_migrations_folder)
  if ! ispath(SearchLight.LOG_PATH)
    mkpath(SearchLight.LOG_PATH)
    setup_loggers()
  end

  open(joinpath(SearchLight.CONFIG_PATH, SearchLight.SEARCHLIGHT_DB_CONFIG_FILE_NAME), "w") do f
    write(f, SearchLight.FileTemplates.new_db_config(adapter))
  end

  open(app_name * ".jl", "w") do f
    write(f, SearchLight.FileTemplates.new_app_loader(app_name))
  end

  open(SearchLight.SEARCHLIGHT_BOOTSTRAP_FILE_NAME, "w") do f
    write(f, SearchLight.FileTemplates.new_app_bootstrap(app_name))
  end

  open(SearchLight.SEARCHLIGHT_INFO_FILE_NAME, "w") do f
    write(f, SearchLight.FileTemplates.new_app_info(app_name))
  end

  log("New app ready at $(pwd())")

  nothing
end
const new_app = new_db_config


"""
"""
function resource_does_not_exist(resource_path::String, file_name::String) :: Bool
  if isfile(joinpath(resource_path, file_name))
    log("File already exists, $(joinpath(resource_path, file_name)) - skipping", :warn)
    return false
  end

  true
end


"""
"""
function model_file_name(resource_name::Union{String,Symbol})
  string(resource_name) * ".jl"
end


"""
"""
function validator_file_name(resource_name::Union{String,Symbol})
  string(resource_name) * SearchLight.SEARCHLIGHT_VALIDATOR_FILE_POSTFIX
end


"""
"""
function create_migrations_table()
  SearchLight.create_migrations_table()
end


"""
    db_init() :: Bool

Sets up the DB tables used by Genie.
"""
function db_init() :: Bool
  SearchLight.create_migrations_table(SearchLight.config.db_migrations_table_name)
end
const init = db_init

end
