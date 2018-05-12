"""
Provides functionality for working with database migrations.
"""
module Migration

using SearchLight, SearchLight.FileTemplates, Millboard, SearchLight.Configuration, Logger, Macros, Database

import Base.showerror


"""

"""
type DatabaseMigration # todo: rename the "migration_" prefix for the fields
  migration_hash::String
  migration_file_name::String
  migration_module_name::String
end


"""

"""
type UnsupportedException <: Exception
  method_name::Symbol
  adapter_name::Symbol
end
Base.showerror(io::IO, e::UnsupportedException) = print(io, "Method $(e.method_name) is not supported by $(e.adapter_name)")


"""

"""
type IrreversibleMigration <: Exception
  migration_name::Symbol
end
Base.showerror(io::IO, e::IrreversibleMigration) = print(io, "Migration $(e.migration_name) is not reversible")


"""
    new(migration_name::String, content::String = "") :: Void
    new(cmd_args::Dict{String,Any}, config::Configuration.Settings) :: Void

Creates a new default migration file and persists it to disk in the configured migrations folder.
"""
function new_table(migration_name::String, resource::String) :: Void
  mfn = migration_file_name(migration_name)

  ispath(mfn) && error("Migration file already exists")
  ispath(SearchLight.config.db_migrations_folder) || mkpath(SearchLight.config.db_migrations_folder)

  open(mfn, "w") do f
    write(f, SearchLight.FileTemplates.new_table_migration(migration_module_name(migration_name), resource))
  end

  Logger.log("New table migration created at $mfn")

  nothing
end


"""
"""
function new(migration_name::String) :: Void
  mfn = migration_file_name(migration_name)

  ispath(mfn) && error("Migration file already exists")
  ispath(SearchLight.config.db_migrations_folder) || mkpath(SearchLight.config.db_migrations_folder)

  open(mfn, "w") do f
    write(f, SearchLight.FileTemplates.new_migration(migration_module_name(migration_name)))
  end

  Logger.log("New table migration created at $mfn")

  nothing
end


"""
    migration_hash() :: String

Computes a unique hash for a migration identifier.
"""
function migration_hash() :: String
  m = match(r"(\d*)-(\d*)-(\d*)T(\d*):(\d*):(\d*)\.(\d*)", "$(Dates.unix2datetime(time()))")

  join(m.captures)
end


"""
    migration_file_name(migration_name::String) :: String
    migration_file_name(cmd_args::Dict{String,Any}, config::Configuration.Settings) :: String

Computes the name of a new migration file.
"""
function migration_file_name(migration_name::String) :: String
  joinpath(SearchLight.config.db_migrations_folder, migration_hash() * "_" * migration_name * ".jl")
end
function migration_file_name(cmd_args::Dict{String,Any}, config::Configuration.Settings) :: String
  joinpath(config.db_migrations_folder, migration_hash() * "_" * cmd_args["migration:new"] * ".jl")
end


"""
    migration_module_name(underscored_migration_name::String) :: String

Computes the name of the module of the migration based on the input from the user (migration name).
"""
function migration_module_name(underscored_migration_name::String) :: String
  mapreduce( x -> ucfirst(x), *, split(replace(underscored_migration_name, ".jl", ""), "_") )
end


"""
    last_up(; force = false) :: Void

Migrates up the last migration. If `force` is `true`, the migration will be executed even if it's already up.
"""
function last_up(; force = false) :: Void
  run_migration(last_migration(), :up, force = force)
end
function up(; force = false) :: Void
  last_up(force = force)
end


"""
    last_down() :: Void

Migrates down the last migration. If `force` is `true`, the migration will be executed even if it's already down.
"""
function last_down(; force = false) :: Void
  run_migration(last_migration(), :down, force = force)
end
function down(; force = false) :: Void
  last_down(force = force)
end


"""
    up(migration_module_name::String; force::Bool = false) :: Void
    up_by_module_name(migration_module_name::String; force::Bool = false) :: Void

Runs up the migration corresponding to `migration_module_name`.
"""
function up(migration_module_name::String; force::Bool = false) :: Void
  migration = migration_by_module_name(migration_module_name)
  if ! isnull(migration)
    run_migration(Base.get(migration), :up, force = force)
  else
    error("Migration $migration_module_name not found")
  end
end
function up_by_module_name(migration_module_name::Union{String,Symbol,Module}; force::Bool = false) :: Void
  up(migration_module_name |> string, force = force)
end


"""
    down(migration_module_name::String; force::Bool = false) :: Void
    down_by_module_name(migration_module_name::String; force::Bool = false) :: Void

Runs down the migration corresponding to `migration_module_name`.
"""
function down(migration_module_name::String; force::Bool = false) :: Void
  migration = migration_by_module_name(migration_module_name)
  if ! isnull(migration)
    run_migration(Base.get(migration), :down, force = force)
  else
    error("Migration $migration_module_name not found")
  end
end
function down_by_module_name(migration_module_name::Union{String,Symbol,Module}; force::Bool = false) :: Void
  down(migration_module_name |> string, force = force)
end


"""
    migration_by_module_name(migration_module_name::String) :: Nullable{DatabaseMigration}

Computes the migration that corresponds to `migration_module_name`.
"""
function migration_by_module_name(migration_module_name::String) :: Nullable{DatabaseMigration}
  ids, migrations = all_migrations()
  for id in ids
    migration = migrations[id]
    if migration.migration_module_name == migration_module_name
      return Nullable(migration)
    end
  end

  Nullable()
end


"""
    all_migrations() :: Tuple{Vector{String},Dict{String,DatabaseMigration}}

Returns the list of all the migrations.
"""
function all_migrations() :: Tuple{Vector{String},Dict{String,DatabaseMigration}}
  migrations = String[]
  migrations_files = Dict{String,DatabaseMigration}()
  for f in readdir(SearchLight.config.db_migrations_folder)
    if ismatch(r"\d{16,17}_.*\.jl", f)
      parts = map(x -> String(x), split(f, "_", limit = 2))
      push!(migrations, parts[1])
      migrations_files[parts[1]] = DatabaseMigration(parts[1], f, migration_module_name(parts[2]))
    end
  end

  sort!(migrations), migrations_files
end


"""
    last_migration() :: DatabaseMigration

Returns the last created migration.
"""
function last_migration() :: DatabaseMigration
  migrations, migrations_files = all_migrations()
  migrations_files[migrations[end]]
end


"""
    run_migration(migration::DatabaseMigration, direction::Symbol; force = false) :: Void

Runs `migration` in up or down, per `directon`. If `force` is true, the migration is run regardless of its current status (already `up` or `down`).
"""
function run_migration(migration::DatabaseMigration, direction::Symbol; force = false) :: Void
  if ! force
    if  ( direction == :up    && in(migration.migration_hash, upped_migrations()) ) ||
        ( direction == :down  && in(migration.migration_hash, downed_migrations()) )
      Logger.log("Skipping, migration is already $direction")
      return
    end
  end

  try
    m = include(abspath(joinpath(SearchLight.config.db_migrations_folder, migration.migration_file_name)))
    Base.invokelatest(getfield(m, direction))
    # getfield(m, direction)()

    store_migration_status(migration, direction, force = force)

    ! SearchLight.config.suppress_output && Logger.log("Executed migration $(migration.migration_module_name) $(direction)")
  catch ex
    Logger.log("Failed executing migration $(migration.migration_module_name) $(direction)", :err)
    Logger.log(string(ex), :err)
    Logger.log("$(@__FILE__):$(@__LINE__)", :err)

    rethrow(ex)
  end

  nothing
end


"""
    store_migration_status(migration::DatabaseMigration, direction::Symbol) :: Void

Persists the `direction` of the `migration` into the database.
"""
function store_migration_status(migration::DatabaseMigration, direction::Symbol; force = false) :: Void
  try
    if direction == :up
      SearchLight.query_raw("INSERT INTO $(SearchLight.config.db_migrations_table_name) VALUES ('$(migration.migration_hash)')", system_query = true)
    else
      SearchLight.query_raw("DELETE FROM $(SearchLight.config.db_migrations_table_name) WHERE version = ('$(migration.migration_hash)')", system_query = true)
    end
  catch ex
    Logger.log(string(ex), :err)
    Logger.log(@location_in_file, :err)

    force || rethrow(ex)
  end

  nothing
end


"""
    upped_migrations() :: Vector{String}

List of all migrations that are `up`.
"""
function upped_migrations() :: Vector{String}
  result = SearchLight.query("SELECT version FROM $(SearchLight.config.db_migrations_table_name) ORDER BY version DESC", system_query = true)

  String[string(x) for x = result[:version]]
end


"""
    downed_migrations() :: Vector{String}

List of all migrations that are `down`.
"""
function downed_migrations() :: Vector{String}
  upped = upped_migrations()
  filter(m -> ! in(m, upped), all_migrations()[1])
end


"""
    status() :: Void

Prints a table that displays the `direction` of each migration.
"""
function status() :: Void
  migrations, migrations_files = all_migrations()
  up_migrations = upped_migrations()
  arr_output = []

  for m in migrations
    sts = ( findfirst(up_migrations, m) > 0 ) ? :up : :down
    push!(arr_output, [migrations_files[m].migration_module_name * ": " * uppercase(string(sts)); migrations_files[m].migration_file_name])
  end

  Millboard.table(arr_output, :colnames => ["Module name & status \nFile name "], :rownames => []) |> println

  nothing
end


"""
    all_with_status() :: Tuple{Vector{String},Dict{String,Dict{Symbol,Any}}}

Returns a list of all the migrations and their status.
"""
function all_with_status() :: Tuple{Vector{String},Dict{String,Dict{Symbol,Any}}}
  migrations, migrations_files = all_migrations()
  up_migrations = upped_migrations()
  indexes = String[]
  result = Dict{String,Dict{Symbol,Any}}()

  for m in migrations
    status = ( findfirst(up_migrations, m) > 0 ) ? :up : :down
    push!(indexes, migrations_files[m].migration_hash)
    result[migrations_files[m].migration_hash] = Dict(
      :migration => DatabaseMigration(migrations_files[m].migration_hash, migrations_files[m].migration_file_name, migrations_files[m].migration_module_name),
      :status => status
    )
  end

  indexes, result
end


"""
    all_down() :: Void

Runs all migrations `down`.
"""
function all_down(; confirm = true) :: Void
  if confirm
    print_with_color(:yellow, "!!!WARNING!!! This will run down all the migration, potentially leading to irrecuperable data loss! You have 5 seconds to cancel this. ")
    sleep(3)
    print_with_color(:yellow, "Running down all the migrations in 2 seconds. ")
    sleep(2)
  end

  i, m = all_with_status()
  for v in values(m)
    if v[:status] == :up
      mm = v[:migration]
      down_by_module_name(mm.migration_module_name)
    end
  end

  nothing
end


"""
    all_up() :: Void

Runs all migrations `up`.
"""
function all_up() :: Void
  i, m = all_with_status()
  for v_hash in i
    v = m[v_hash]
    if v[:status] == :down
      mm = v[:migration]
      up_by_module_name(mm.migration_module_name)
    end
  end

  nothing
end


"""
    function create_table() :: String

Creates a new DB table.
"""
function create_table(f::Function, name::Union{String,Symbol}, options::String = "") :: Void
  SearchLight.create_table(f, string(name), options)
end


"""

"""
function column(name::Union{String,Symbol}, column_type::Symbol, options::String = ""; default::Any = nothing, limit::Union{Int,Void} = nothing, not_null::Bool = false) :: String
  SearchLight.column_definition(string(name), column_type, options, default = default, limit = limit, not_null = not_null)
end


"""

"""
function column_id(name::Union{String,Symbol} = "id", options::String = ""; constraint::String = "", nextval::String = "") :: String
  SearchLight.column_id(string(name), options, constraint = constraint, nextval = nextval)
end


"""

"""
function add_index(table_name::Union{String,Symbol}, column_name::Union{String,Symbol}; name::Union{String,Symbol} = "", unique::Bool = false, order::Symbol = :none) :: Void
  SearchLight.add_index(string(table_name), string(column_name), name = string(name), unique = unique, order = order)
end
const create_index = add_index


"""

"""
function add_column(table_name::Union{String,Symbol}, name::Union{String,Symbol}, column_type::Symbol; default::Any = nothing, limit::Union{Int,Void} = nothing, not_null::Bool = false) :: Void
  SearchLight.add_column(string(table_name), string(name), column_type, default = default, limit = limit, not_null = not_null)
end


"""

"""
function drop_table(name::Union{String,Symbol}) :: Void
  SearchLight.drop_table(string(name))
end


"""

"""
function remove_column(table_name::Union{String,Symbol}, name::Union{String,Symbol}) :: Void
  SearchLight.remove_column(string(table_name), string(name))
end


"""

"""
function remove_index_by_name(table_name::Union{String,Symbol}, name::Union{String,Symbol}) :: Void
  SearchLight.remove_index(string(table_name), string(name))
end


"""

"""
function remove_index(table_name::Union{String,Symbol}, column_name::Union{String,Symbol}) :: Void
  Migration.remove_index_by_name(string(table_name), index_name(string(table_name), string(column_name)))
end


"""

"""
function index_name(table_name::Union{String,Symbol}, column_name::Union{String,Symbol}) :: String
  string(table_name) * "__" * "idx_" * string(column_name)
end


"""

"""
function create_sequence(name::Union{String,Symbol}) :: Void
  SearchLight.create_sequence(string(name))
end


"""

"""
function create_sequence(table_name::Union{String,Symbol}, column_name::Union{String,Symbol}) :: Void
  SearchLight.create_sequence(sequence_name(table_name, column_name))
end


"""

PostgreSQL specific.
"""
function sequence_name(table_name::Union{String,Symbol}, column_name::Union{String,Symbol}) :: String
  string(table_name) * "__" * "seq_" * string(column_name)
end


"""

PostgreSQL specific.
"""
function constraint(table_name::Union{String,Symbol}, column_name::Union{String,Symbol}) :: String
  "CONSTRAINT $( index_name(table_name, column_name) )"
end


"""

PostgreSQL specific.
"""
function nextval(table_name::Union{String,Symbol}, column_name::Union{String,Symbol}) :: String
  "NEXTVAL('$( sequence_name(table_name, column_name) )')"
end


"""

PostgreSQL specific.
"""
function column_id_sequence(table_name::Union{String,Symbol}, column_name::Union{String,Symbol})
  SearchLight.query("ALTER SEQUENCE $(sequence_name(table_name, column_name)) OWNED BY $table_name.$column_name")
end


"""

"""
function remove_sequence_by_name(name::Union{String,Symbol}, options::String = "") :: Void
  SearchLight.remove_sequence(string(name), options)
end


"""

"""
function remove_sequence(table_name::Union{String,Symbol}, column_name::Union{String,Symbol}, options::String = "") :: Void
  Migration.remove_sequence_by_name(sequence_name(string(table_name), string(column_name)), options)
end
const drop_sequence = remove_sequence

end

const Migrations = Migration
