"""
Generates various Genie files.
"""
module Generator

using Logger, SearchLight.FileTemplates, Inflector, SearchLight.Configuration, SearchLight, Migration


"""
    new_model(cmd_args::Dict{String,Any}) :: Void

Generates a new SearchLight model file and persists it to the resources folder.
"""
function new_model(cmd_args::Dict{String,Any}) :: Void
  resource_name = ucfirst(cmd_args["model:new"])
  if Inflector.is_singular(resource_name)
    resource_name = Inflector.to_plural(resource_name) |> Base.get
  end

  resource_path = setup_resource_path(resource_name)
  mfn = model_file_name(resource_name)
  write_resource_file(resource_path, mfn, resource_name, :model) &&
    Logger.log("New model created at $(joinpath(resource_path, mfn))")

  nothing
end


"""
    function new_resource(resource_name::String, config::Settings) :: Void

Generates all the files associated with a new resource and persists them to the resources folder.
"""
function new_resource(resource_name::String) :: Void
  sf = Inflector.to_singular(resource_name)
  model_name = (isnull(sf) ? resource_name : Base.get(sf)) |> ucfirst
  new_model(Dict{String,Any}("model:new" => model_name))
  new_migration(Dict{String,Any}("migration:new" => resource_name))

  resource_name = ucfirst(resource_name)
  if Inflector.is_singular(resource_name)
    resource_name = Inflector.to_plural(resource_name) |> Base.get
  end

  resource_path = setup_resource_path(resource_name)
  for (resource_file, resource_type) in [(validator_file_name(resource_name), :validator)]
    write_resource_file(resource_path, resource_file, resource_name, resource_type) &&
      Logger.log("New $resource_file created at $(joinpath(resource_path, resource_file))")
  end

  isdir(SearchLight.TEST_PATH_UNIT) || mkpath(SearchLight.TEST_PATH_UNIT)
  test_file = resource_name * SearchLight.TEST_FILE_IDENTIFIER |> lowercase
  write_resource_file(SearchLight.TEST_PATH_UNIT, test_file, resource_name, :test) &&
    Logger.log("New $test_file created at $(joinpath(SearchLight.TEST_PATH_UNIT, test_file))")

  SearchLight.load_resources()

  nothing
end


"""
"""
function new_migration(cmd_args::Dict{String,Any}) :: Void
  resource_name = ucfirst(cmd_args["migration:new"])

  resource_name = ucfirst(resource_name)
  if Inflector.is_singular(resource_name)
    resource_name = Inflector.to_plural(resource_name) |> Base.get
  end

  migration_name = "create_table_" * lowercase(resource_name)
  Migration.new(migration_name)

  nothing
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
    Logger.log(ex, :err)
  end

  true
end


"""
"""
function new_db_config(adapter::Symbol = :sqlite) :: Void
  isdir(SearchLight.CONFIG_PATH) || mkpath(SearchLight.CONFIG_PATH)
  isdir(SearchLight.config.db_migrations_folder) || mkpath(SearchLight.config.db_migrations_folder)
  if ! ispath(SearchLight.LOG_PATH)
    mkpath(SearchLight.LOG_PATH)
    Logger.setup_loggers()
  end

  open(joinpath(SearchLight.CONFIG_PATH, SearchLight.SEARCHLIGHT_DB_CONFIG_FILE_NAME), "w") do f
    write(f, SearchLight.FileTemplates.new_db_config(adapter))
  end

  nothing
end


"""
"""
function resource_does_not_exist(resource_path::String, file_name::String) :: Bool
  if isfile(joinpath(resource_path, file_name))
    Logger.log("File already exists, $(joinpath(resource_path, file_name)) - skipping", :err)
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

end
