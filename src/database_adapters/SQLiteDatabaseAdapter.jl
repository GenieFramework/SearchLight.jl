module SQLiteDatabaseAdapter

import Revise
import SQLite, DataFrames, DataStreams, Logging
using SearchLight, SearchLight.Database

export DatabaseHandle, ResultHandle


#
# Setup
#


const DB_ADAPTER = SQLite
const COLUMN_NAME_FIELD_NAME = :name

const DatabaseHandle = DB_ADAPTER.DB
const ResultHandle   = Union{Vector{Any}, DataFrames.DataFrame, Vector{Tuple}, Vector{Tuple{Int64}}}

const TYPE_MAPPINGS = Dict{Symbol,Symbol}( # Julia => SQLite
  :char       => :CHARACTER,
  :string     => :VARCHAR,
  :text       => :TEXT,
  :integer    => :INTEGER,
  :int        => :INTEGER,
  :float      => :FLOAT,
  :decimal    => :DECIMAL,
  :datetime   => :DATETIME,
  :timestamp  => :INTEGER,
  :time       => :TIME,
  :date       => :DATE,
  :binary     => :BLOB,
  :boolean    => :BOOLEAN,
  :bool       => :BOOLEAN
)

const SELECT_LAST_ID_QUERY_START = "; SELECT CASE WHEN last_insert_rowid() = 0 THEN"
const SELECT_LAST_ID_QUERY_END = "ELSE last_insert_rowid() END AS id"

@inline function db_adapter()::Symbol
  Symbol(DB_ADAPTER)
end


#
# Connection
#


"""
    connect(conn_data::Dict)::DatabaseHandle
    function connect()::DatabaseHandle

Connects to the database defined in conn_data["filename"] and returns a handle.
If no conn_data is provided, a temporary, in-memory database will be used.
"""
@inline function connect(conn_data::Dict)::DatabaseHandle
  if ! haskey(conn_data, "filename")
    conn_data["filename"] = if haskey(conn_data, "host") && conn_data["host"] != nothing
                              conn_data["host"]
                            elseif haskey(conn_data, "database") && conn_data["database"] != nothing
                              conn_data["database"]
                            end
  end

  try
    SQLite.DB(conn_data["filename"])
  catch ex
    @error "Invalid DB connection settings"

    rethrow(ex)
  end
end
@inline function connect()::DatabaseHandle
  try
    SQLite.DB()
  catch ex
    @error "Invalid DB connection settings"

    rethrow(ex)
  end
end


"""
    disconnect(conn::DatabaseHandle)::Nothing

Disconnects from database.
"""
@inline function disconnect(conn::DatabaseHandle)::Nothing
  conn = nothing
end


#
# Utility
#


"""
    table_columns_sql(table_name::String)::String

Returns the adapter specific query for SELECTing table columns information corresponding to `table_name`.
"""
@inline function table_columns_sql(table_name::String) :: String
  "PRAGMA table_info(`$table_name`)"
end


"""
    create_migrations_table(table_name::String)::Bool

Runs a SQL DB query that creates the table `table_name` with the structure needed to be used as the DB migrations table.
The table should contain one column, `version`, unique, as a string of maximum 30 chars long.
Returns `true` on success.
"""
@inline function create_migrations_table(table_name::String) :: Bool
  "CREATE TABLE `$table_name` (
    `version` varchar(30) NOT NULL DEFAULT '',
    PRIMARY KEY (`version`)
  )" |> Database.query

  @info "Created table $table_name"

  true
end


#
# Data sanitization
#


"""
    escape_column_name(c::String, conn::DatabaseHandle)::String

Escapes the column name using native features provided by the database backend.

# Examples
```julia
julia>
```
"""
@inline function escape_column_name(c::String, conn::DatabaseHandle) :: String
  DB_ADAPTER.esc_id(c)
end


"""
    escape_value{T}(v::T, conn::DatabaseHandle)::T

Escapes the value `v` using native features provided by the database backend if available.

# Examples
```julia
julia>
```
"""
@inline function escape_value(v::T, conn::DatabaseHandle) :: T where {T}
  isa(v, Number) ? v : "'$(replace(string(v), "'"=>"''"))'"
end


#
# Query execution
#


"""
    query(sql::String, suppress_output::Bool, conn::DatabaseHandle)::DataFrames.DataFrame

Executes the `sql` query against the database backend and returns a DataFrame result.

# Examples:
```julia
julia> query(SearchLight.to_fetch_sql(Article, SQLQuery(limit = 5)), false, Database.connection)

2017-01-16T21:36:21.566 - info: SQL QUERY: SELECT \"articles\".\"id\" AS \"articles_id\", \"articles\".\"title\" AS \"articles_title\", \"articles\".\"summary\" AS \"articles_summary\", \"articles\".\"content\" AS \"articles_content\", \"articles\".\"updated_at\" AS \"articles_updated_at\", \"articles\".\"published_at\" AS \"articles_published_at\", \"articles\".\"slug\" AS \"articles_slug\" FROM \"articles\" LIMIT 5

  0.000985 seconds (16 allocations: 576 bytes)

5×7 DataFrames.DataFrame
...
```
"""
function query(sql::String, suppress_output::Bool, conn::DatabaseHandle) :: DataFrames.DataFrame
  parts::Vector{String} = if occursin(SELECT_LAST_ID_QUERY_START, sql)
                            split(sql, SELECT_LAST_ID_QUERY_START)
                          else
                            String[sql]
                          end

  length(parts) == 2 && (parts[2] = SELECT_LAST_ID_QUERY_START * parts[2])

  result =  if suppress_output || ( ! SearchLight.config.log_db && ! SearchLight.config.log_queries )
              if length(parts) == 2
                SQLite.Query(conn, parts[1]) |> DataFrames.DataFrame
                SQLite.Query(conn, parts[2]) |> DataFrames.DataFrame
              else
                SQLite.Query(conn, parts[1]) |> DataFrames.DataFrame
              end
            else
              if length(parts) == 2
                @info parts[1]
                @time SQLite.Query(conn, parts[1]) |> DataFrames.DataFrame

                @info parts[2]
                @time SQLite.Query(conn, parts[2]) |> DataFrames.DataFrame
              else
                @info parts[1]
                @time SQLite.Query(conn, parts[1]) |> DataFrames.DataFrame
              end
            end

  result
end


"""
"""
@inline function to_find_sql(m::Type{T}, q::SQLQuery, joins::Union{Nothing,Vector{SQLJoin{N}}} = nothing)::String where {T<:AbstractModel, N<:Union{Nothing,AbstractModel}}
  sql::String = ( "$(to_select_part(m, q.columns, joins)) $(to_from_part(m)) $(to_join_part(m, joins)) $(to_where_part(q.where)) " *
                      "$(to_group_part(q.group)) $(to_having_part(q.having)) $(to_order_part(m, q.order)) " *
                      "$(to_limit_part(q.limit)) $(to_offset_part(q.offset))") |> strip
  replace(sql, r"\s+"=>" ")
end

const to_fetch_sql = to_find_sql


"""
"""
function to_store_sql(m::T; conflict_strategy = :error)::String where {T<:AbstractModel} # upsert strateygy = :none | :error | :ignore | :update
  uf = SearchLight.persistable_fields(m)

  sql = if ! ispersisted(m) || (ispersisted(m) && conflict_strategy == :update)
    pos = findfirst(x -> x == m._id, uf)
    pos > 0 && splice!(uf, pos)

    fields = SQLColumn(uf)
    vals = join( map(x -> string(SearchLight.to_sqlinput(m, Symbol(x), getfield(m, Symbol(x)))), uf), ", ")

    "INSERT $( conflict_strategy == :ignore ? " OR IGNORE" : "" ) INTO $(m._table_name) ( $fields ) VALUES ( $vals )"
  else
    "UPDATE $(m._table_name) SET $(update_query_part(m))"
  end

  sql * "$SELECT_LAST_ID_QUERY_START $( Nullables.isnull(getfield(m, Symbol(m._id))) ? -1 : getfield(m, Symbol(m._id)) |> Base.get ) $SELECT_LAST_ID_QUERY_END"
end


"""

"""
@inline function delete_all(m::Type{T}; truncate::Bool = true, reset_sequence::Bool = true, cascade::Bool = false)::Nothing where {T<:AbstractModel}
  _m::T = m()
  "DELETE FROM $(_m._table_name)" |> SearchLight.query

  nothing
end


"""

"""
@inline function delete(m::T)::T where {T<:AbstractModel}
  "DELETE FROM $(m._table_name) WHERE $(m._id) = '$(m.id |> Base.get)'" |> SearchLight.query

  tmp::T = T()
  m.id = tmp.id

  m
end


"""

"""
@inline function count(m::Type{T}, q::SQLQuery = SQLQuery())::Int where {T<:AbstractModel}
  count_column = SQLColumn("COUNT(*) AS __cid", raw = true)
  q = SearchLight.clone(q, :columns, push!(q.columns, count_column))

  finddf(m, q)[1, Symbol("__cid")]
end


"""

"""
@inline function update_query_part(m::T)::String where {T<:AbstractModel}
  update_values = join(map(x -> "$(string(SQLColumn(x))) = $( string(SearchLight.to_sqlinput(m, Symbol(x), getfield(m, Symbol(x)))) )", SearchLight.persistable_fields(m)), ", ")

  " $update_values WHERE $(m._table_name).$(m._id) = '$(Base.get(m.id))'"
end


"""

"""
@inline function column_data_to_column_name(column::SQLColumn, column_data::Dict{Symbol,Any})::String
  "$(SearchLight.to_fully_qualified(column_data[:column_name], column_data[:table_name])) AS $( isempty(column_data[:alias]) ? SearchLight.to_sql_column_name(column_data[:column_name], column_data[:table_name]) : column_data[:alias] )"
end


"""

"""
@inline function to_select_part(m::Type{T}, cols::Vector{SQLColumn}, joins::Union{Nothing,Vector{SQLJoin{N}}} = nothing)::String where {T<:AbstractModel, N<:Union{Nothing,AbstractModel}}
  "SELECT " * SearchLight.Database._to_select_part(m, cols, (joins === nothing ? SQLJoin[] : joins))
end


"""

"""
@inline function to_from_part(m::Type{T})::String where {T<:AbstractModel}
  "FROM " * SearchLight.Database.escape_column_name(m()._table_name)
end


@inline function to_where_part(w::Vector{SQLWhereEntity})::String
  where = isempty(w) ?
          "" :
          "WHERE " * (string(first(w).condition) == "AND" ? "TRUE " : "FALSE ") * join(map(wx -> string(wx), w), " ")

  replace(where, r"WHERE TRUE AND "i => "WHERE ")
end


"""

"""
@inline function to_order_part(m::Type{T}, o::Vector{SQLOrder})::String where {T<:AbstractModel}
  isempty(o) ?
    "" :
    "ORDER BY " * join(map(x -> (! SearchLight.is_fully_qualified(x.column.value) ? SearchLight.to_fully_qualified(m, x.column) : x.column.value) * " " * x.direction, o), ", ")
end


"""

"""
@inline function to_group_part(g::Vector{SQLColumn}) :: String
  isempty(g) ?
    "" :
    " GROUP BY " * join(map(x -> string(x), g), ", ")
end


"""

"""
@inline function to_limit_part(l::SQLLimit) :: String
  l.value != "ALL" ? "LIMIT " * (l |> string) : ""
end


"""

"""
@inline function to_offset_part(o::Int) :: String
  o != 0 ? "OFFSET " * (o |> string) : ""
end


"""

"""
@inline function to_having_part(h::Vector{SQLWhereEntity}) :: String
  having =  isempty(h) ?
            "" :
            "HAVING " * (string(first(h).condition) == "AND" ? "TRUE " : "FALSE ") * join(map(w -> string(w), h), " ")

  replace(having, r"HAVING TRUE AND "i => "HAVING ")
end


"""

"""
function to_join_part(m::Type{T}, joins::Union{Nothing,Vector{SQLJoin{N}}} = nothing)::String where {T<:AbstractModel, N<:Union{Nothing,AbstractModel}}
  joins === nothing && return ""

  _m::T = m()
  join_part = ""

  join_part * join( map(x -> string(x), joins), " " )
end


"""
    cast_type(v::Bool)::Union{Bool,Int,Char,String}

Converts the Julia type to the corresponding type in the database.
"""
@inline function cast_type(v::Bool) :: Int
  v ? 1 : 0
end


"""

"""
@inline function create_table_sql(f::Function, name::String, options::String = "") :: String
  "CREATE TABLE $name (" * join(f()::Vector{String}, ", ") * ") $options" |> strip
end


"""

"""
@inline function column_sql(name::String, column_type::Symbol, options::String = ""; default::Any = nothing, limit::Union{Int,Nothing} = nothing, not_null::Bool = false) :: String
  "$name $(TYPE_MAPPINGS[column_type] |> string) " *
    (isa(limit, Int) ? "($limit)" : "") *
    (default == nothing ? "" : " DEFAULT $default ") *
    (not_null ? " NOT NULL " : "") *
    options
end


"""

"""
@inline function column_id_sql(name::String = "id", options::String = ""; constraint::String = "", nextval::String = "") :: String
  "$name INTEGER PRIMARY KEY $options"
end


"""

"""
@inline function add_index_sql(table_name::String, column_name::String; name::String = "", unique::Bool = false, order::Symbol = :none) :: String
  name = isempty(name) ? Database.index_name(table_name, column_name) : name
  "CREATE $(unique ? "UNIQUE" : "") INDEX $(name) ON $table_name ($column_name)"
end


"""

"""
@inline function add_column_sql(table_name::String, name::String, column_type::Symbol; default::Any = nothing, limit::Union{Int,Nothing} = nothing, not_null::Bool = false) :: String
  "ALTER TABLE $table_name ADD $(column_sql(name, column_type, default = default, limit = limit, not_null = not_null))"
end


"""

"""
@inline function drop_table_sql(name::String) :: String
  "DROP TABLE $name"
end


"""

"""
@inline function remove_column_sql(table_name::String, name::String) :: Nothing
  throw(SearchLight.UnsupportedException(:remove_column, Symbol(DB_ADAPTER)))
end


"""

"""
@inline function remove_index_sql(table_name::String, name::String) :: String
  "DROP INDEX $name"
end


"""

"""
@inline function rand(m::Type{T}; limit = 1)::Vector{T} where {T<:AbstractModel}
  SearchLight.find(m, SQLQuery(limit = SQLLimit(limit), order = [SQLOrder("random()", raw = true)]))
end

end
