module PostgreSQLDatabaseAdapter

import Revise
import LibPQ, DataFrames, DataStreams, Logging
using SearchLight, SearchLight.Database, SearchLight.Exceptions

export DatabaseHandle, ResultHandle


#
# Setup
#


const DB_ADAPTER = LibPQ
const DEFAULT_PORT = 5432

const COLUMN_NAME_FIELD_NAME = :column_name

const DatabaseHandle = DB_ADAPTER.Connection
const ResultHandle   = DB_ADAPTER.Result

const TYPE_MAPPINGS = Dict{Symbol,Symbol}( # Julia / Postgres
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


"""
    db_adapter()::Symbol

The name of the underlying database adapter (driver).
"""
function db_adapter()::Symbol
  Symbol(DB_ADAPTER)
end


#
# Connection
#


"""
    connect(conn_data::Dict)::DatabaseHandle

Connects to the database and returns a handle.
"""
function connect(conn_data::Dict)::DatabaseHandle
  dns = String[]

  get(conn_data, "host", nothing) != nothing      && push!(dns, "host=" * conn_data["host"])
  get(conn_data, "hostaddr", nothing) != nothing  && push!(dns, "hostaddr=" * conn_data["hostaddr"])
  get(conn_data, "port", nothing) != nothing      && push!(dns, "port=" * string(conn_data["port"]))
  get(conn_data, "database", nothing) != nothing  && push!(dns, "dbname=" * conn_data["database"])
  get(conn_data, "username", nothing) != nothing  && push!(dns, "user=" * conn_data["username"])
  get(conn_data, "password", nothing) != nothing  && push!(dns, "password=" * conn_data["password"])
  get(conn_data, "passfile", nothing) != nothing  && push!(dns, "passfile=" * conn_data["passfile"])
  get(conn_data, "connecttimeout", nothing) != nothing  && push!(dns, "connect_timeout=" * conn_data["connecttimeout"])
  get(conn_data, "clientencoding", nothing) != nothing  && push!(dns, "client_encoding=" * conn_data["clientencoding"])

  try
    DB_ADAPTER.Connection(join(dns, " "))
  catch ex
    @error "Invalid DB connection settings"

    rethrow(ex)
  end
end


"""
    disconnect(conn::DatabaseHandle)::Nothing

Disconnects from database.
"""
function disconnect(conn::DatabaseHandle) :: Nothing
  DB_ADAPTER.close(conn)
end


#
# Utility
#


"""
    table_columns_sql(table_name::String)::String

Returns the adapter specific query for SELECTing table columns information corresponding to `table_name`.
"""
function table_columns_sql(table_name::String)::String
  "SELECT column_name FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = '$table_name'"
end


"""
    create_migrations_table(table_name::String)::Bool

Runs a SQL DB query that creates the table `table_name` with the structure needed to be used as the DB migrations table.
The table should contain one column, `version`, unique, as a string of maximum 30 chars long.
Returns `true` on success.
"""
function create_migrations_table(table_name::String) :: Bool
  "CREATE TABLE $table_name (version varchar(30))" |> SearchLight.Database.query

  @info "Created table $table_name"

  true
end


#
# Data sanitization
#


"""
    escape_column_name(c::String, conn::DatabaseHandle)::String

Escapes the column name.

# Examples
```julia
julia>
```
"""
function escape_column_name(c::String, conn::DatabaseHandle)::String
  """\"$(replace(c, "\""=>"'"))\""""
end


"""
    escape_value{T}(v::T, conn::DatabaseHandle)::T

Escapes the value `v` using native features provided by the database backend if available.

# Examples
```julia
julia>
```
"""
function escape_value(v::T, conn::DatabaseHandle)::T where {T}
  isa(v, Number) ? v : "E'$(replace(string(v), "'"=>"\\'"))'"
end


#
# Query execution
#


"""
    query(sql::String, suppress_output::Bool, conn::DatabaseHandle)::DataFrames.DataFrame

Executes the `sql` query against the database backend and returns a DataFrame result.

# Examples:
```julia
julia> PostgreSQLDatabaseAdapter.query(SearchLight.to_fetch_sql(Article, SQLQuery(limit = 5)), false, Database.connection)

2017-01-16T21:36:21.566 - info: SQL QUERY: SELECT \"articles\".\"id\" AS \"articles_id\", \"articles\".\"title\" AS \"articles_title\", \"articles\".\"summary\" AS \"articles_summary\", \"articles\".\"content\" AS \"articles_content\", \"articles\".\"updated_at\" AS \"articles_updated_at\", \"articles\".\"published_at\" AS \"articles_published_at\", \"articles\".\"slug\" AS \"articles_slug\" FROM \"articles\" LIMIT 5

  0.000985 seconds (16 allocations: 576 bytes)

5×7 DataFrames.DataFrame
...
```
"""
function query(sql::String, suppress_output::Bool, conn::DatabaseHandle) :: DataFrames.DataFrame
  result = if SearchLight.config.log_queries
    @info sql
    @time DB_ADAPTER.execute(conn, sql)
  else
    DB_ADAPTER.execute(conn, sql)
  end

  if ( DB_ADAPTER.error_message(result) != "" )
    throw(SearchLight.Exceptions.DatabaseAdapterException("$(string(DB_ADAPTER)) error: $(DB_ADAPTER.errstring(result)) [$(DB_ADAPTER.errcode(result))]"))
  end

  result |> DataFrames.DataFrame
end


"""
"""
function to_find_sql(m::Type{T}, q::SearchLight.SQLQuery, joins::Union{Nothing,Vector{SearchLight.SQLJoin{N}}} = nothing)::String where {T<:SearchLight.AbstractModel, N<:Union{Nothing,SearchLight.AbstractModel}}
  sql::String = ( "$(to_select_part(m, q.columns, joins)) $(to_from_part(m)) $(to_join_part(m, joins)) $(to_where_part(q.where)) " *
                      "$(to_group_part(q.group)) $(to_having_part(q.having)) $(to_order_part(m, q.order)) " *
                      "$(to_limit_part(q.limit)) $(to_offset_part(q.offset))") |> strip
  replace(sql, r"\s+"=>" ")
end

const to_fetch_sql = to_find_sql


"""
"""
function to_store_sql(m::T; conflict_strategy = :error)::String where {T<:SearchLight.AbstractModel}
  uf = SearchLight.persistable_fields(m)

  sql = if ! SearchLight.ispersisted(m) || (SearchLight.ispersisted(m) && conflict_strategy == :update)
    pos = findfirst(x -> x == SearchLight.primary_key_name(m), uf)
    pos != nothing && splice!(uf, pos)

    fields = SearchLight.SQLColumn(uf)
    vals = join( map(x -> string(SearchLight.to_sqlinput(m, Symbol(x), getfield(m, Symbol(x)))), uf), ", ")

    "INSERT INTO $(SearchLight.table_name(m)) ( $fields ) VALUES ( $vals )" *
        if ( conflict_strategy == :error ) ""
        elseif ( conflict_strategy == :ignore ) " ON CONFLICT DO NOTHING"
        elseif ( conflict_strategy == :update &&
          getfield(m, Symbol(SearchLight.primary_key_name(m))).value !== nothing )
            " ON CONFLICT ($(SearchLight.primary_key_name(m))) DO UPDATE SET $(update_query_part(m))"
        else ""
        end
  else
    "UPDATE $(SearchLight.table_name(m)) SET $(update_query_part(m))"
  end

  return sql * " RETURNING $(SearchLight.primary_key_name(m))"
end


"""

"""
function delete_all(m::Type{T}; truncate::Bool = true, reset_sequence::Bool = true, cascade::Bool = false)::Nothing where {T<:SearchLight.AbstractModel}
  _m::T = m()
  if truncate
    sql = "TRUNCATE $(SearchLight.table_name(_m))"
    reset_sequence ? sql * " RESTART IDENTITY" : ""
    cascade ? sql * " CASCADE" : ""
  else
    sql = "DELETE FROM $(SearchLight.table_name(_m))"
  end

  SearchLight.query(sql)

  nothing
end


"""

"""
function delete(m::T)::T where {T<:SearchLight.AbstractModel}
  sql = "DELETE FROM $(SearchLight.table_name(m)) WHERE $(SearchLight.primary_key_name(m)) = '$(m.id.value)'"
  SearchLight.query(sql)

  m.id = SearchLight.DbId()

  m
end


"""

"""
function count(m::Type{T}, q::SearchLight.SQLQuery = SearchLight.SQLQuery())::Int where {T<:SearchLight.AbstractModel}
  count_column = SearchLight.SQLColumn("COUNT(*) AS __cid", raw = true)
  q = SearchLight.clone(q, :columns, push!(q.columns, count_column))

  SearchLight.finddf(m, q)[1, Symbol("__cid")]
end


"""

"""
function update_query_part(m::T)::String where {T<:SearchLight.AbstractModel}
  update_values = join(map(x -> "$(string(SearchLight.SQLColumn(x))) = $(string(SearchLight.to_sqlinput(m, Symbol(x), getfield(m, Symbol(x)))) )", SearchLight.persistable_fields(m)), ", ")

  " $update_values WHERE $(SearchLight.table_name(m)).$(SearchLight.primary_key_name(m)) = '$(m.id.value)'"
end


"""

"""
function column_data_to_column_name(column::SearchLight.SQLColumn, column_data::Dict{Symbol,Any}) :: String
  "$(SearchLight.to_fully_qualified(column_data[:column_name], column_data[:table_name])) AS $(isempty(column_data[:alias]) ? SearchLight.to_sql_column_name(column_data[:column_name], column_data[:table_name]) : column_data[:alias] )"
end


"""

"""
function to_select_part(m::Type{T}, cols::Vector{SearchLight.SQLColumn}, joins::Union{Nothing,Vector{SQLJoin{N}}} = nothing)::String where {T<:SearchLight.AbstractModel, N<:Union{Nothing,SearchLight.AbstractModel}}
  "SELECT " * SearchLight.Database._to_select_part(m, cols, joins)
end


"""

"""
function to_from_part(m::Type{T})::String where {T<:SearchLight.AbstractModel}
  "FROM " * SearchLight.Database.escape_column_name(SearchLight.table_name(SearchLight.disposable_instance(m)))
end


function to_where_part(w::Vector{SearchLight.SQLWhereEntity})::String
  where = isempty(w) ?
          "" :
          "WHERE " * (string(first(w).condition) == "AND" ? "TRUE " : "FALSE ") * join(map(wx -> string(wx), w), " ")

  replace(where, r"WHERE TRUE AND "i => "WHERE ")
end


"""

"""
function to_order_part(m::Type{T}, o::Vector{SearchLight.SQLOrder})::String where {T<:SearchLight.AbstractModel}
  isempty(o) ?
    "" :
    "ORDER BY " * join(map(x -> (! SearchLight.is_fully_qualified(x.column.value) ? SearchLight.to_fully_qualified(m, x.column) : x.column.value) * " " * x.direction, o), ", ")
end


"""

"""
function to_group_part(g::Vector{SearchLight.SQLColumn}) :: String
  isempty(g) ?
    "" :
    " GROUP BY " * join(map(x -> string(x), g), ", ")
end


"""

"""
function to_limit_part(l::SearchLight.SQLLimit) :: String
  l.value != "ALL" ? "LIMIT " * (l |> string) : ""
end


"""

"""
function to_offset_part(o::Int) :: String
  o != 0 ? "OFFSET " * (o |> string) : ""
end


"""

"""
function to_having_part(h::Vector{SearchLight.SQLWhereEntity}) :: String
  having =  isempty(h) ?
            "" :
            "HAVING " * (string(first(h).condition) == "AND" ? "TRUE " : "FALSE ") * join(map(w -> string(w), h), " ")

  replace(having, r"HAVING TRUE AND "i => "HAVING ")
end


"""

"""
function to_join_part(m::Type{T}, joins::Union{Nothing,Vector{SQLJoin{N}}} = nothing)::String where {T<:SearchLight.AbstractModel, N<:Union{Nothing,SearchLight.AbstractModel}}
  joins === nothing && return ""

  _m::T = m()
  join_part = ""

  join_part * join( map(x -> string(x), joins), " " )
end


"""
    cast_type(v::Bool)::Union{Bool,Int,Char,String}

Converts the Julia type to the corresponding type in the database.
"""
function cast_type(v::Bool) :: Union{Bool,Int,Char,String}
  v ? "true" : "false"
end

"""

"""
function create_table_sql(f::Function, name::String, options::String = "") :: String
  "CREATE TABLE $name (" * join(f()::Vector{String}, ", ") * ") $options" |> strip
end


"""

"""
function column_sql(name::String, column_type::Symbol, options::String = ""; default::Any = nothing, limit::Union{Int,Nothing} = nothing, not_null::Bool = false)::String
  "$name $(TYPE_MAPPINGS[column_type] |> string) " *
    (isa(limit, Int) ? "($limit)" : "") *
    (default === nothing ? "" : " DEFAULT $default ") *
    (not_null ? " NOT NULL " : "") *
    options
end


"""

"""
function column_id_sql(name::String = "id", options::String = ""; constraint::String = "", nextval::String = "") :: String
  "$name SERIAL $constraint PRIMARY KEY $nextval $options"
end


"""

"""
function add_index_sql(table_name::String, column_name::String; name::String = "", unique::Bool = false, order::Symbol = :none) :: String
  name = isempty(name) ? SearchLight.index_name(table_name, column_name) : name
  "CREATE $(unique ? "UNIQUE" : "") INDEX $(name) ON $table_name ($column_name)"
end


"""

"""
function add_column_sql(table_name::String, name::String, column_type::Symbol; default::Any = nothing, limit::Union{Int,Nothing} = nothing, not_null::Bool = false) :: String
  "ALTER TABLE $table_name ADD $(column_sql(name, column_type, default = default, limit = limit, not_null = not_null))"
end


"""

"""
function drop_table_sql(name::String) :: String
  "DROP TABLE $name"
end


"""

"""
function remove_column_sql(table_name::String, name::String, options::String = "") :: Nothing
  "ALTER TABLE $table_name DROP COLUMN $name $options"
end


"""

"""
function remove_index_sql(table_name::String, name::String, options::String = "") :: String
  "DROP INDEX $name $options"
end


"""

"""
function create_sequence_sql(name::String) :: String
  "CREATE SEQUENCE $name"
end


"""

"""
function remove_sequence_sql(name::String, options::String = "") :: String
  "DROP SEQUENCE $name $options"
end


"""

"""
function rand(m::Type{T}; limit = 1)::Vector{T} where {T<:SearchLight.AbstractModel}
  SearchLight.find(m, SearchLight.SQLQuery(limit = SearchLight.SQLLimit(limit), order = [SearchLight.SQLOrder("random()", raw = true)]))
end

end
