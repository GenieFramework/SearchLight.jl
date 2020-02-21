"""
Generates various SearchLight files.
"""
module Generator

import Revise
import Unicode, Logging
using SearchLight

include("FileTemplates.jl")
using .FileTemplates

"""
    newmodel(name::Union{String,Symbol}; path::Union{String,Nothing} = nothing, pluralize::Bool = true) :: Nothing

Generates a new SearchLight model file and persists it to the resources folder.
"""
function newmodel(name::Union{String,Symbol}; path::Union{String,Nothing} = nothing, pluralize::Bool = true) :: Nothing
  name = string(name) |> uppercasefirst
  model_name = SearchLight.Inflector.is_singular(name) ? SearchLight.Inflector.to_plural(name) : name

  model_path = setup_resource_path(model_name, path)
  mfn = model_file_name(model_name)
  write_resource_file(model_path, mfn, model_name, :model, pluralize = pluralize) &&
    @info "New model created at $(abspath(joinpath(model_path, mfn)))"

  nothing
end


"""
    newresource(resource_name::Union{String,Symbol}) :: Nothing

Generates all the files associated with a new resource and persists them to the resources folder.
"""
function newresource(resource_name::Union{String,Symbol}; path::Union{String,Nothing} = nothing, pluralize::Bool = true) :: Nothing
  resource_name = string(resource_name)

  sf = SearchLight.Inflector.tosingular(resource_name)

  model_name = (sf === nothing ? resource_name : sf) |> uppercasefirst
  newmodel(model_name, path = path, pluralize = pluralize)
  new_table_migration(resource_name, pluralize = pluralize)

  resource_name = uppercasefirst(resource_name)
  pluralize && SearchLight.Inflector.is_singular(resource_name) &&
    (resource_name = SearchLight.Inflector.to_plural(resource_name))

  resource_path = setup_resource_path(resource_name, path)
  for (resource_file, resource_type) in [(validator_file_name(resource_name), :validator)]
    write_resource_file(resource_path, resource_file, resource_name, resource_type, pluralize = pluralize) &&
      @info "New $resource_type created at $(abspath(joinpath(resource_path, resource_file)))"
  end

  isdir(SearchLight.TEST_PATH) || mkpath(SearchLight.TEST_PATH)
  test_file = resource_name * SearchLight.TEST_FILE_IDENTIFIER |> lowercase
  write_resource_file(SearchLight.TEST_PATH, test_file, resource_name, :test, pluralize = pluralize) &&
    @info "New unit test created at $(abspath(joinpath(SearchLight.TEST_PATH, test_file)))"

  nothing
end


function new_table_migration(migration_name::Union{String,Symbol}; pluralize::Bool = true) :: Nothing
  resource_name = uppercasefirst(string(migration_name))

  SearchLight.Inflector.is_singular(resource_name) && pluralize &&
    (resource_name = SearchLight.Inflector.to_plural(resource_name))

  migration_name = "create_table_" * lowercase(resource_name)
  SearchLight.Migration.new_table(migration_name, lowercase(resource_name))

  nothing
end


function newmigration(migration_name::Union{String,Symbol}) :: Nothing
  migration_name = replace(uppercasefirst(string(migration_name)) |> lowercase, " "=>"_")

  SearchLight.Migration.new(migration_name)

  nothing
end


"""
    setup_resource_path(resource_name::String) :: String

Computes and creates the directories structure needed to persist a new resource.
"""
function setup_resource_path(resource_name::String, path::Union{String,Nothing} = nothing) :: String
  resource_path = path === nothing ?
                  joinpath(SearchLight.RESOURCES_PATH, lowercase(resource_name)) :
                  path

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
function write_resource_file(resource_path::String, file_name::String, resource_name::String, resource_type::Symbol; pluralize::Bool = true) :: Bool
  resource_name = (pluralize ? SearchLight.Inflector.tosingular(resource_name) : resource_name) |> SearchLight.Inflector.from_underscores

  try
    if resource_type == :model
      resource_does_not_exist(resource_path, file_name) || return true
      open(joinpath(resource_path, file_name), "w") do f
        write(f, FileTemplates.newmodel(resource_name, pluralize = pluralize))
      end
    end
  catch ex
    @error ex
  end

  try
    if resource_type == :validator
      resource_does_not_exist(resource_path, file_name) || return true
      open(joinpath(resource_path, file_name), "w") do f
        write(f, FileTemplates.newvalidator(resource_name, pluralize = pluralize))
      end
    end
  catch ex
    @error ex
  end

  try
    if resource_type == :test
      resource_does_not_exist(resource_path, file_name) || return true
      open(joinpath(resource_path, file_name), "w") do f
        uname = SearchLight.Inflector.from_underscores(resource_name)
        uname = pluralize ? SearchLight.Inflector.to_plural(uname) : uname

        write(f, FileTemplates.newtest(resource_name))
      end
    end
  catch ex
    @error ex
  end

  true
end


function newconfig(path::String = SearchLight.DB_PATH; filename = SearchLight.SEARCHLIGHT_DB_CONFIG_FILE_NAME) :: Nothing
  ispath(path) || mkpath(path)
  filepath = joinpath(path, filename) |> abspath
  open(filepath, "w") do io
    write(io, FileTemplates.newconfig())
  end

  @info "New config file create at $(filepath)"

  nothing
end


function resource_does_not_exist(resource_path::String, file_name::String) :: Bool
  if isfile(joinpath(resource_path, file_name))
    @warn "File already exists, $(joinpath(resource_path, file_name)) - skipping"

    return false
  end

  true
end


function model_file_name(resource_name::Union{String,Symbol})
  "$resource_name.jl"
end


function validator_file_name(resource_name::Union{String,Symbol})
  string(resource_name, SearchLight.SEARCHLIGHT_VALIDATOR_FILE_POSTFIX)
end

end