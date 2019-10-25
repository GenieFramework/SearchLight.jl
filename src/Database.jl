module Database

import Revise
import YAML, DataFrames, Logging
using SearchLight, SearchLight.Configuration


const ADAPTERS_FOLDER = joinpath(@__DIR__, "database_adapters")


function setup_adapter(adapter = SearchLight.config.db_config_settings["adapter"] * "DatabaseAdapter") :: Union{Bool,Nothing}
  Core.eval(@__MODULE__, Meta.parse("""include(joinpath(ADAPTERS_FOLDER, "$adapter.jl"))"""))
  Core.eval(@__MODULE__, Meta.parse("using .$adapter"))

  Core.eval(@__MODULE__, :(db_adapter = Symbol($adapter)))
  ! Core.isdefined(@__MODULE__, :DatabaseAdapter) && Core.eval(@__MODULE__, :(const DatabaseAdapter = $db_adapter))
  ! Core.isdefined(@__MODULE__, :DatabaseHandle) && Core.eval(@__MODULE__, :(const DatabaseHandle = $db_adapter.DatabaseHandle))
  ! Core.isdefined(@__MODULE__, :ResultHandle) && Core.eval(@__MODULE__, :(const ResultHandle = $db_adapter.ResultHandle))

  Core.eval(@__MODULE__, :(export DatabaseAdapter))

  true
end



"""
    connect()::DatabaseHandle
    connect(conn_settings::Dict{String,Any})::DatabaseHandle

Connects to the DB and returns a database handler. If used without arguments, it defaults to using `config.db_config_settings`

# Examples
```julia
julia> Database.connect()
PostgreSQL.PostgresDatabaseHandle(Ptr{Nothing} @0x00007fbf3839f360,0x00000000,false)

julia> dict = config.db_config_settings
Dict{String,Any} with 6 entries:
  "host"     => "localhost"
  "password" => "adrian"
  "username" => "adrian"
  "port"     => 5432
  "database" => "blogjl_dev"
  "adapter"  => "PostgreSQL"

julia> Database.connect(dict)
PostgreSQL.PostgresDatabaseHandle(Ptr{Nothing} @0x00007fbf3839f360,0x00000000,false)
```
"""
@inline function connect() #::DatabaseHandle
  connect(SearchLight.config.db_config_settings)
end
function connect(conn_settings::Dict)
  isdefined(@__MODULE__, :DatabaseAdapter) || connect!(conn_settings)

  c = Base.invokelatest(DatabaseAdapter.connect, conn_settings) #::DatabaseHandle
  Core.eval(@__MODULE__, :(CONNECTION = $c))

  c
end


@inline function connect!(conn_settings::Dict)
  SearchLight.config.db_config_settings["adapter"] = conn_settings["adapter"]
  setup_adapter() && Database.connect(conn_settings) #::DatabaseHandle
end


"""

"""
@inline function disconnect(conn)
  DatabaseAdapter.disconnect(conn)
end
@inline function disconnect()
  DatabaseAdapter.disconnect(CONNECTION)
end


"""
    create_database()::Bool
    create_database(db_name::String)::Bool

Invokes the database adapter's create database method. If invoked without param, it defaults to the
database name defined in `config.db_config_settings`
"""
@inline function create_database() :: Bool
  create_database(SearchLight.config.db_config_settings["database"])
end
@inline function create_database(db_name::String)::Bool
  DatabaseAdapter.create_database(db_name)
end


"""
    create_migrations_table(table_name::String)::Bool

Invokes the database adapter's create migrations table method. If invoked without param, it defaults to the
database name defined in `config.db_migrations_table_name`
"""
@inline function create_migrations_table(table_name::String) :: Bool
  DatabaseAdapter.create_migrations_table(table_name)
end


"""
    init()::Bool

Sets up the DB tables used by SearchLight.
"""
@inline function init() :: Bool
  DatabaseAdapter.create_migrations_table(SearchLight.config.db_migrations_table_name)
end


@inline function escape_column_name(c::String)
  result =  try
              DatabaseAdapter.escape_column_name(c, CONNECTION)::String
            catch ex
              @error ex
            end

  result
end


@inline function escape_value(v::T)::T where {T}
  result =  try
              DatabaseAdapter.escape_value(v, CONNECTION)
            catch ex
              @error ex
            end

  result
end


@inline function table_columns(table_name::String) :: DataFrames.DataFrame
  query(DatabaseAdapter.table_columns_sql(table_name), suppress_output = true)
end


"""
    query(sql::String; suppress_output::Bool = false)::DataFrames.DataFrame

Executes the `sql` query against the database adapter and returns a DataFrame result.
Optionally logs the result DataFrame.

# Examples:
```julia
julia> SearchLight.to_fetch_sql(Article, SQLQuery(limit = 5)) |> Database.query;

2017-01-16T21:33:40.079 - info: SQL QUERY: SELECT \"articles\".\"id\" AS \"articles_id\", \"articles\".\"title\" AS \"articles_title\", \"articles\".\"summary\" AS \"articles_summary\", \"articles\".\"content\" AS \"articles_content\", \"articles\".\"updated_at\" AS \"articles_updated_at\", \"articles\".\"published_at\" AS \"articles_published_at\", \"articles\".\"slug\" AS \"articles_slug\" FROM \"articles\" LIMIT 5

  0.001172 seconds (16 allocations: 576 bytes)

2017-01-16T21:33:40.089 - info: 5×7 DataFrames.DataFrame
...
```
"""
@inline function query(sql::String; suppress_output::Bool = false, system_query::Bool = false) :: DataFrames.DataFrame
  df::DataFrames.DataFrame =  DatabaseAdapter.query(sql, (suppress_output || system_query), CONNECTION)
  (! suppress_output && ! system_query && SearchLight.config.log_db) && @info(df)

  df
end


"""

"""
@inline function to_find_sql(m::Type{T}, q::SearchLight.SQLQuery, joins::Union{Nothing,Vector{SearchLight.SQLJoin{N}}} = nothing)::String where {T<:SearchLight.AbstractModel, N<:Union{Nothing,SearchLight.AbstractModel}}
  DatabaseAdapter.to_find_sql(m, q, joins)
end

const to_fetch_sql = to_find_sql


"""

"""
@inline function to_store_sql(m::T; conflict_strategy = :error)::String where {T<:SearchLight.AbstractModel}
  DatabaseAdapter.to_store_sql(m, conflict_strategy = conflict_strategy)
end


"""

"""
@inline function delete_all(m::Type{T}; truncate::Bool = true, reset_sequence::Bool = true, cascade::Bool = false)::Nothing where {T<:SearchLight.AbstractModel}
  DatabaseAdapter.delete_all(m, truncate = truncate, reset_sequence = reset_sequence, cascade = cascade)
end


"""

"""
@inline function delete(m::T)::T where {T<:SearchLight.AbstractModel}
  DatabaseAdapter.delete(m)
end


"""

"""
@inline function count(m::Type{T}, q::SearchLight.SQLQuery = SearchLight.SQLQuery())::Int where {T<:SearchLight.AbstractModel}
  DatabaseAdapter.count(m, q)
end


"""

"""
@inline function update_query_part(m::T)::String where {T<:SearchLight.AbstractModel}
  DatabaseAdapter.update_query_part(m)
end


"""

"""
@inline function to_select_part(m::Type{T}, cols::Vector{SearchLight.SQLColumn}, joins = SearchLight.SQLJoin[])::String where {T<:SearchLight.AbstractModel}
  DatabaseAdapter.to_select_part(m, cols, joins)
end
"""

"""
function _to_select_part(m::Type{T}, cols::Vector{SearchLight.SQLColumn}, joins = SearchLight.SQLJoin[])::String where {T<:SearchLight.AbstractModel}
  _m::T = m()

  if ! isempty(cols)
    table_columns = []
    cols = vcat(cols, columns_from_joins(joins))

    for column in cols
      push!(table_columns, prepare_column_name(column, _m))
    end

    return join(table_columns, ", ")
  else
    tbl_cols = join(SearchLight.to_fully_qualified_sql_column_names(_m, SearchLight.persistable_fields(_m), escape_columns = true), ", ")
    table_columns = isempty(tbl_cols) ? String[] : vcat(tbl_cols, map(x -> prepare_column_name(x, _m), columns_from_joins(joins)))

    return join(table_columns, ", ")
  end
end


"""

"""
@inline function to_from_part(m::Type{T})::String where {T<:SearchLight.AbstractModel}
  DatabaseAdapter.to_from_part(m)
end


"""

"""
@inline function to_where_part(w::Vector{SearchLight.SQLWhereEntity})::String
  DatabaseAdapter.to_where_part(w)
end


"""

"""
@inline function to_order_part(m::Type{T}, o::Vector{SearchLight.SQLOrder})::String where {T<:SearchLight.AbstractModel}
  DatabaseAdapter.to_order_part(m, o)
end


"""

"""
@inline function to_group_part(group::Vector{SearchLight.SQLColumn}) :: String
  DatabaseAdapter.to_group_part(group)
end


"""

"""
@inline function to_limit_part(limit::SearchLight.SQLLimit) :: String
  DatabaseAdapter.to_limit_part(limit)
end


"""

"""
@inline function to_offset_part(offset::Int) :: String
  DatabaseAdapter.to_offset_part(offset)
end


"""

"""
@inline function to_having_part(having::Vector{SearchLight.SQLHaving}) :: String
  DatabaseAdapter.to_having_part(having)
end


"""

"""
@inline function to_join_part(m::Type{T}, joins = SearchLight.SQLJoin[])::String where {T<:SearchLight.AbstractModel}
  DatabaseAdapter.to_join_part(m, joins)
end


"""
  columns_from_joins(joins::Vector{SQLJoin})::Vector{SQLColumn}

Extracts columns from joins param and adds to be used for the SELECT part
"""
function columns_from_joins(joins::Vector{SearchLight.SQLJoin})::Vector{SearchLight.SQLColumn}
  jcols = SearchLight.SQLColumn[]
  for j in joins
    jcols = vcat(jcols, j.columns)
  end

  jcols
end


"""

"""
function prepare_column_name(column::SearchLight.SQLColumn, _m::T)::String where {T<:SearchLight.AbstractModel}
  if column.raw
    column.value |> string
  else
    column_data::Dict{Symbol,Any} = SearchLight.from_literal_column_name(column.value)
    if ! haskey(column_data, :table_name)
      column_data[:table_name] = SearchLight.table_name(_m)
    end
    if ! haskey(column_data, :alias)
      column_data[:alias] = ""
    end

    DatabaseAdapter.column_data_to_column_name(column, column_data)
  end
end


"""

"""
@inline function rand(m::Type{T}; limit = 1)::Vector{T} where {T<:SearchLight.AbstractModel}
  DatabaseAdapter.rand(m, limit = limit)
end


"""

"""
@inline function index_name(table_name::Union{String,Symbol}, column_name::Union{String,Symbol}) :: String
  string(table_name) * "__" * "idx_" * string(column_name)
end

end