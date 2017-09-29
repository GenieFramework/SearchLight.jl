"""
Generates various Genie files.
"""
module Generator

using Logger, FileTemplates, Inflector, SearchLight.Configuration, SearchLight, Migration


"""
    function new_model(model_name::String) :: Void

Generates a new SearchLight model file and persists it to the resources folder.
"""
function new_model(model_name::String) :: Void
  resource_name = ucfirst(model_name)
  if Inflector.is_singular(resource_name)
    resource_name = Inflector.to_plural(resource_name) |> Base.get
  end

  resource_path = setup_resource_path(resource_name)
  write_resource_file(resource_path, SearchLight.SEARCHLIGHT_MODEL_FILE_NAME, resource_name) &&
    Logger.log("New model created at $(joinpath(resource_path, SearchLight.SEARCHLIGHT_MODEL_FILE_NAME))")

  nothing
end


"""
    function new_resource(resource_name::String, config::Settings) :: Void

Generates all the files associated with a new resource and persists them to the resources folder.
"""
function new_resource(resource_name::String) :: Void
  sf = Inflector.to_singular(resource_name)
  model_name = (isnull(sf) ? resource_name : Base.get(sf)) |> ucfirst
  new_model(model_name)

  resource_name = ucfirst(resource_name)
  if Inflector.is_singular(resource_name)
    resource_name = Inflector.to_plural(resource_name) |> Base.get
  end

  migration_name = "create_table_" * lowercase(resource_name)
  Migration.new(migration_name)

  resource_path = setup_resource_path(resource_name)
  for resource_file in [SearchLight.SEARCHLIGHT_VALIDATOR_FILE_NAME]
    write_resource_file(resource_path, resource_file, resource_name) &&
      Logger.log("New $resource_file created at $(joinpath(resource_path, resource_file))")
  end

  isdir(SearchLight.TEST_PATH_UNIT) || mkpath(SearchLight.TEST_PATH_UNIT)
  test_file = resource_name * SearchLight.TEST_FILE_IDENTIFIER |> lowercase
  write_resource_file(SearchLight.TEST_PATH_UNIT, test_file, resource_name) &&
    Logger.log("New $test_file created at $(joinpath(SearchLight.TEST_PATH_UNIT, test_file))")

  nothing
end


"""
    setup_resource_path(resource_name::String) :: String

Computes and creates the directories structure needed to persist a new resource.
"""
function setup_resource_path(resource_name::String) :: String
  resources_dir = SearchLight.RESOURCES_PATH
  resource_path = joinpath(resources_dir, lowercase(resource_name))

  isdir(resource_path) || mkpath(resource_path)

  resource_path
end


"""
    write_resource_file(resource_path::String, file_name::String, resource_name::String) :: Bool

Generates all resouce files and persists them to disk.
"""
function write_resource_file(resource_path::String, file_name::String, resource_name::String) :: Bool
  if isfile(joinpath(resource_path, file_name))
    Logger.log("File already exists, $(joinpath(resource_path, file_name)) - skipping", :err)
    return false
  end

  f = open(joinpath(resource_path, file_name), "w")

  if file_name == SearchLight.SEARCHLIGHT_MODEL_FILE_NAME
    write(f, FileTemplates.new_model( Base.get(Inflector.to_singular( Inflector.from_underscores(resource_name) )), resource_name ))
  elseif file_name == SearchLight.SEARCHLIGHT_VALIDATOR_FILE_NAME
    write(f, FileTemplates.new_validator( Base.get(Inflector.to_singular(resource_name)) |> Inflector.from_underscores ))
  elseif endswith(file_name, SearchLight.TEST_FILE_IDENTIFIER)
    write(f, FileTemplates.new_test(Base.get(Inflector.to_plural( Inflector.from_underscores(resource_name) )), Base.get(Inflector.to_singular( Inflector.from_underscores(resource_name) )) ))
  else
    error("Not supported, $file_name")
  end

  close(f)

  true
end


function new_db_config(adapter::Symbol = :sqlite) :: Void
  isdir(SearchLight.CONFIG_PATH) || mkpath(SearchLight.CONFIG_PATH)
  open(joinpath(SearchLight.CONFIG_PATH, SearchLight.SEARCHLIGHT_DB_CONFIG_FILE_NAME), "w") do f
    write(f, FileTemplates.new_db_config(adapter))
  end

  nothing
end

end
