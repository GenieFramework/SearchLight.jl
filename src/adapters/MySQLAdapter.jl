module MySQLAdapter

import Revise
import MySQL, DataFrames, DataStreams, Logging
import SearchLight

export DatabaseHandle, ResultHandle


#
# Setup
#


const DEFAULT_PORT = 3306

const COLUMN_NAME_FIELD_NAME = :Field

function SearchLight.column_field_name()
  COLUMN_NAME_FIELD_NAME
end

const DatabaseHandle = MySQL.MySQLHandle
const ResultHandle   = DataStreams.Data.Rows

const TYPE_MAPPINGS = Dict{Symbol,Symbol}( # Julia => MySQL
  :char       => :CHARACTER,
  :string     => :VARCHAR,
  :text       => :TEXT,
  :integer    => :INTEGER,
  :int        => :INTEGER,
  :float      => :FLOAT,
  :decimal    => :DECIMAL,
  :datetime   => :DATETIME,
  :timestamp  => :TIMESTAMP,
  :time       => :TIME,
  :date       => :DATE,
  :binary     => :BLOB,
  :boolean    => :BOOLEAN,
  :bool       => :BOOLEAN
)

const CONNECTIONS = DatabaseHandle[]

#
# Connection
#


"""
    connect(conn_data::Dict)::DatabaseHandle

Connects to the database and returns a handle.
"""
function SearchLight.connect(conn_data::Dict = SearchLight.config.db_config_settings) :: DatabaseHandle
  push!(CONNECTIONS,
        MySQL.connect(conn_data["host"], conn_data["username"], get(conn_data, "password", "");
                  db    = conn_data["database"],
                  port  = get(conn_data, "port", 3306),
                  opts  = Dict(getfield(MySQL.API, Symbol(k))=>v for (k,v) in conn_data["options"]))
  )[end]
end


"""
    disconnect(conn::DatabaseHandle)::Nothing

Disconnects from database.
"""
function SearchLight.disconnect(conn::DatabaseHandle = CONNECTIONS[end]) :: Nothing
  MySQL.disconnect(conn)
end


#
# Utility
#

"""
    columns{T<:AbstractModel}(m::Type{T})::DataFrames.DataFrame
    columns{T<:AbstractModel}(m::T)::DataFrames.DataFrame

Returns a DataFrame representing schema information for the database table columns associated with `m`.
"""
function SearchLight.columns(m::T)::DataFrames.DataFrame where {T<:SearchLight.AbstractModel}
  SearchLight.query(table_columns_sql(SearchLight.table_name(m)), internal = true)
end
function SearchLight.columns(m::Type{T})::DataFrames.DataFrame where {T<:SearchLight.AbstractModel}
  SearchLight.columns(m())
end


"""
    table_columns_sql(table_name::String)::String

Returns the adapter specific query for SELECTing table columns information corresponding to `table_name`.
"""
function table_columns_sql(table_name::String) :: String
  "SHOW COLUMNS FROM `$table_name`"
end


"""
    create_migrations_table(table_name::String)::Bool

Runs a SQL DB query that creates the table `table_name` with the structure needed to be used as the DB migrations table.
The table should contain one column, `version`, unique, as a string of maximum 30 chars long.
Returns `true` on success.
"""
function SearchLight.Migration.create_migrations_table(table_name::String = SearchLight.config.db_migrations_table_name)::Bool
  "CREATE TABLE `$table_name` (
    `version` varchar(30) NOT NULL DEFAULT '',
    PRIMARY KEY (`version`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8" |> SearchLight.query

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
function SearchLight.escape_column_name(c::String, conn::DatabaseHandle = CONNECTIONS[end]) :: String
  join(["""`$(replace(cx, "`"=>"-"))`""" for cx in split(c, '.')], '.')
end


"""
    escape_value{T}(v::T, conn::DatabaseHandle)::T

Escapes the value `v` using native features provided by the database backend.

# Examples
```julia
julia>
```
"""
function SearchLight.escape_value(v::T, conn::DatabaseHandle = CONNECTIONS[end])::T where {T}
  isa(v, Number) ? v : "'$(MySQL.escape(conn, string(v)))'"
end


#
# Query execution
#


function SearchLight.query(sql::String, conn::DatabaseHandle = CONNECTIONS[end]; internal = false) :: DataFrames.DataFrame
  try
    _result = if SearchLight.config.log_queries && ! internal
      @info sql
      @time MySQL.Query(conn, sql)
    else
      MySQL.Query(conn, sql)
    end

    result = if startswith(sql, "INSERT ")
      DataFrames.DataFrame(SearchLight.LAST_INSERT_ID_LABEL => last_insert_id(conn))
    elseif startswith(sql, "ALTER ") || startswith(sql, "CREATE ") || startswith(sql, "DROP ") || startswith(sql, "DELETE ") || startswith(sql, "UPDATE ")
      DataFrames.DataFrame(:result => "OK")
    else
      DataFrames.DataFrame(_result)
    end
  catch ex
    @error """MySQL error when running
              $sql """

    if isa(ex, MySQL.MySQLInternalError) && (ex.errno == 2013 || ex.errno == 2006)
      @warn ex, " ...Attempting reconnection"

      pop!(CONNECTIONS)

      SearchLight.query(sql, SearchLight.connect())
    else
      rethrow(ex)
    end
  end
end


function SearchLight.to_find_sql(m::Type{T}, q::SearchLight.SQLQuery, joins::Union{Nothing,Vector{SearchLight.SQLJoin{N}}} = nothing)::String where {T<:SearchLight.AbstractModel, N<:Union{Nothing,SearchLight.AbstractModel}}
  sql::String = ( "$(SearchLight.to_select_part(m, q.columns, joins)) $(SearchLight.to_from_part(m)) $(SearchLight.to_join_part(m, joins)) $(SearchLight.to_where_part(q.where)) " *
                      "$(SearchLight.to_group_part(q.group)) $(SearchLight.to_having_part(q.having)) $(SearchLight.to_order_part(m, q.order)) " *
                      "$(SearchLight.to_limit_part(q.limit)) $(SearchLight.to_offset_part(q.offset))") |> strip
  replace(sql, r"\s+"=>" ")
end


function SearchLight.to_store_sql(m::T; conflict_strategy = :error)::String where {T<:SearchLight.AbstractModel}
  uf = SearchLight.persistable_fields(m)

  sql = if ! SearchLight.ispersisted(m) || (SearchLight.ispersisted(m) && conflict_strategy == :update)
    pos = findfirst(x -> x == SearchLight.primary_key_name(m), uf)
    pos > 0 && splice!(uf, pos)

    fields = SearchLight.SQLColumn(uf)
    vals = join( map(x -> string(SearchLight.to_sqlinput(m, Symbol(x), getfield(m, Symbol(x)))), uf), ", ")

    "INSERT INTO $(m._table_name) ( $fields ) VALUES ( $vals )" *
        if ( conflict_strategy == :error ) ""
        elseif ( conflict_strategy == :ignore ) " ON DUPLICATE KEY UPDATE `$(SearchLight.primary_key_name(m))` = `$(SearchLight.primary_key_name(m))`"
        elseif ( conflict_strategy == :update && getfield(m, Symbol(SearchLight.primary_key_name(m))).value !== nothing )
          " ON DUPLICATE KEY UPDATE $(SearchLight.update_query_part(m))"
        else ""
        end
  else
    "UPDATE $(m._table_name) SET $(SearchLight.update_query_part(m))"
  end

  sql
end


function SearchLight.delete_all(m::Type{T}; truncate::Bool = true, reset_sequence::Bool = true, cascade::Bool = false)::Nothing where {T<:SearchLight.AbstractModel}
  _m::T = m()
  (truncate ? "TRUNCATE $(_m._table_name)" : "DELETE FROM $(_m._table_name)") |> SearchLight.query

  nothing
end


function SearchLight.delete(m::T)::T where {T<:SearchLight.AbstractModel}
  SearchLight.ispersisted(m) || throw(SearchLight.Exceptions.NotPersistedException(m))

  "DELETE FROM $(m._table_name) WHERE $(SearchLight.primary_key_name(m)) = '$(m.id.value)'" |> SearchLight.query

  m.id = SearchLight.DbId()

  m
end


function Base.count(m::Type{T}, q::SearchLight.SQLQuery = SearchLight.SQLQuery())::Int where {T<:SearchLight.AbstractModel}
  count_column = SearchLight.SQLColumn("COUNT(*) AS __cid", raw = true)
  q = SearchLight.clone(q, :columns, push!(q.columns, count_column))

  SearchLight.finddf(m, q)[1, Symbol("__cid")]
end


function SearchLight.update_query_part(m::T)::String where {T<:SearchLight.AbstractModel}
  update_values = join(map(x -> "$(string(SearchLight.SQLColumn(x))) = $(string(SearchLight.to_sqlinput(m, Symbol(x), getfield(m, Symbol(x)))))", SearchLight.persistable_fields(m)), ", ")

  " $update_values WHERE $(m._table_name).$(SearchLight.primary_key_name(m)) = '$(m.id.value)'"
end


function SearchLight.column_data_to_column_name(column::SearchLight.SQLColumn, column_data::Dict{Symbol,Any}) :: String
  "$(SearchLight.to_fully_qualified(column_data[:column_name], column_data[:table_name])) AS $(isempty(column_data[:alias]) ? SearchLight.to_sql_column_name(column_data[:column_name], column_data[:table_name]) : column_data[:alias])"
end


function SearchLight.to_from_part(m::Type{T})::String where {T<:SearchLight.AbstractModel}
  string("FROM ", SearchLight.escape_column_name(m()._table_name, CONNECTIONS[end]))
end


function SearchLight.to_where_part(w::Vector{SearchLight.SQLWhereEntity}) :: String
  where = isempty(w) ?
          "" :
          string("WHERE ", (string(first(w).condition) == "AND" ? "TRUE " : "FALSE "), join(map(wx -> string(wx), w), " "))

  replace(where, r"WHERE TRUE AND "i => "WHERE ")
end


function SearchLight.to_order_part(m::Type{T}, o::Vector{SearchLight.SQLOrder})::String where {T<:SearchLight.AbstractModel}
  isempty(o) ?
    "" :
    string("ORDER BY ", join(map(x -> (! SearchLight.is_fully_qualified(x.column.value) ? SearchLight.to_fully_qualified(m, x.column) : x.column.value) * " " * x.direction, o), ", "))
end


function SearchLight.to_group_part(g::Vector{SearchLight.SQLColumn}) :: String
  isempty(g) ?
    "" :
    string(" GROUP BY ", join(map(x -> string(x), g), ", "))
end


function SearchLight.to_limit_part(l::SearchLight.SQLLimit) :: String
  l.value != "ALL" ? string("LIMIT ", (l |> string)) : ""
end


function SearchLight.to_offset_part(o::Int) :: String
  o != 0 ? string("OFFSET ", (o |> string)) : ""
end


function SearchLight.to_having_part(h::Vector{SearchLight.SQLWhereEntity}) :: String
  having =  isempty(h) ?
            "" :
            string("HAVING ", (string(first(h).condition) == "AND" ? "TRUE " : "FALSE "), join(map(w -> string(w), h), " "))

  replace(having, r"HAVING TRUE AND "i => "HAVING ")
end


function SearchLight.to_join_part(m::Type{T}, joins::Union{Nothing,Vector{SearchLight.SQLJoin{N}}} = nothing)::String where {T<:SearchLight.AbstractModel, N<:Union{Nothing,SearchLight.AbstractModel}}
  joins === nothing && return ""

  join( map(x -> string(x), joins), " " )
end


#### MIGRATIONS ####


function SearchLight.Migration.create_table(f::Function, name::String, options::String = "") :: Nothing
  create_table_sql(f, name, options) |> SearchLight.query

  nothing
end

function create_table_sql(f::Function, name::String, options::String = "") :: String
  "CREATE TABLE `$name` (" * join(f()::Vector{String}, ", ") * ") $options" |> strip
end


function SearchLight.Migration.column(name::String, column_type::Symbol, options::String = ""; default::Any = nothing, limit::Union{Int,Nothing,String} = nothing, not_null::Bool = false)::String
  "`$name` $(TYPE_MAPPINGS[column_type] |> string) " *
    (isa(limit, Int) || isa(limit, String) ? "($limit)" : "") *
    (default === nothing ? "" : " DEFAULT $default ") *
    (not_null ? " NOT NULL " : "") *
    " " * options
end


function SearchLight.Migration.column_id(name::String = "id", options::String = ""; constraint::String = "", nextval::String = "") :: String
  "`$name` INT NOT NULL AUTO_INCREMENT PRIMARY KEY $options"
end


function SearchLight.Migration.add_index(table_name::String, column_name::String; name::String = "", unique::Bool = false, order::Symbol = :none) :: String
  name = isempty(name) ? SearchLight.index_name(table_name, column_name) : name
  "CREATE $(unique ? "UNIQUE" : "") INDEX `$(name)` ON `$table_name` (`$column_name`)" |> SearchLight.query
end


function SearchLight.Migration.add_column(table_name::String, name::String, column_type::Symbol; default::Any = nothing, limit::Union{Int,Nothing} = nothing, not_null::Bool = false) :: String
  "ALTER TABLE `$table_name` ADD $(column_sql(name, column_type, default = default, limit = limit, not_null = not_null))" |> SearchLight.query
end


function SearchLight.Migration.drop_table(name::String) :: String
  "DROP TABLE `$name`" |> SearchLight.query
end


function SearchLight.Migration.remove_column(table_name::String, name::String, options::String = "") :: String
  "ALTER TABLE `$table_name` DROP COLUMN `$name` $options" |> SearchLight.query
end


function SearchLight.Migration.remove_index(table_name::String, name::String, options::String = "") :: String
  "DROP INDEX `$name` ON `$table_name` $options" |> SearchLight.query
end


function Base.rand(m::Type{T}; limit = 1)::Vector{T} where {T<:SearchLight.AbstractModel}
  SearchLight.find(m, SearchLight.SQLQuery(limit = SearchLight.SQLLimit(limit), order = [SearchLight.SQLOrder("rand()", raw = true)]))
end


function last_insert_id(conn)
  MySQL.insertid(conn)
end


function SearchLight.Generator.FileTemplates.adapter_default_config()
  """
  $(SearchLight.config.app_env):
    adapter:  MySQL
    host:     127.0.0.1
    port:     3306
    database: yourdb
    username: root
    password: ""
  """
end

end