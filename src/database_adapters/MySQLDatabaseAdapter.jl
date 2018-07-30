module MySQLDatabaseAdapter

using MySQL, DataFrames, DataStreams
using SearchLight, SearchLight.Database, SearchLight.Logger

export DatabaseHandle, ResultHandle


#
# Setup
#


const DB_ADAPTER = MySQL
const DEFAULT_PORT = 3306

const COLUMN_NAME_FIELD_NAME = :Field

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
  :boolean    => :BOOLEAN
)


function db_adapter()::Symbol
  :MySQL
end


#
# Connection
#


"""
    connect(conn_data::Dict{String,Any})::DatabaseHandle

Connects to the database and returns a handle.
"""
function connect(conn_data::Dict{String,Any})::DatabaseHandle
  try
    MySQL.connect(conn_data["host"],
                  conn_data["username"],
                  (conn_data["password"] == nothing ? "" : conn_data["password"]),
                  db = conn_data["database"],
                  port = (conn_data["port"] == nothing ? 3360 : conn_data["port"]))
  catch ex
    Logger.log("Invalid DB connection settings", :err)
    Logger.log(string(ex), :err)
    Logger.log("$(@__FILE__):$(@__LINE__)", :err)

    rethrow(ex)
  end
end


"""
    disconnect(conn::DatabaseHandle)::Nothing

Disconnects from database.
"""
function disconnect(conn::DatabaseHandle)::Nothing
  MySQL.disconnect(conn)
end


#
# Utility
#


"""
    table_columns_sql(table_name::AbstractString)::String

Returns the adapter specific query for SELECTing table columns information corresponding to `table_name`.
"""
function table_columns_sql(table_name::String)::String
  "SHOW COLUMNS FROM `$table_name`"
end


"""
    create_migrations_table(table_name::String)::Bool

Runs a SQL DB query that creates the table `table_name` with the structure needed to be used as the DB migrations table.
The table should contain one column, `version`, unique, as a string of maximum 30 chars long.
Returns `true` on success.
"""
function create_migrations_table(table_name::String)::Bool
  "CREATE TABLE `$table_name` (
    `version` varchar(30) NOT NULL DEFAULT '',
    PRIMARY KEY (`version`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8" |> Database.query

  Logger.log("Created table $table_name")

  true
end


#
# Data sanitization
#


"""
    escape_column_name(c::AbstractString, conn::DatabaseHandle)::String

Escapes the column name using native features provided by the database backend.

# Examples
```julia
julia>
```
"""
function escape_column_name(c::AbstractString, conn::DatabaseHandle)::String
  """`$(replace(c, "`"=>"-"))`"""
end


"""
    escape_value{T}(v::T, conn::DatabaseHandle)::T

Escapes the value `v` using native features provided by the database backend.

# Examples
```julia
julia>
```
"""
function escape_value(v::T, conn::DatabaseHandle)::T where {T}
  isa(v, Number) ? v : "'$(MySQL.escape(conn, string(v)))'"
end

function mysql_escape(s::AbstractString, conn::DatabaseHandle)
   MySQL.escape(conn, s)
end


#
# Query execution
#


"""
    query_df(sql::AbstractString, suppress_output::Bool, conn::DatabaseHandle)::DataFrames.DataFrame

Executes the `sql` query against the database backend and returns a DataFrame result.

# Examples:
```julia
julia> query_df(SearchLight.to_fetch_sql(Article, SQLQuery(limit = 5)), false, Database.connection())

2017-01-16T21:36:21.566 - info: SQL QUERY: SELECT \"articles\".\"id\" AS \"articles_id\", \"articles\".\"title\" AS \"articles_title\", \"articles\".\"summary\" AS \"articles_summary\", \"articles\".\"content\" AS \"articles_content\", \"articles\".\"updated_at\" AS \"articles_updated_at\", \"articles\".\"published_at\" AS \"articles_published_at\", \"articles\".\"slug\" AS \"articles_slug\" FROM \"articles\" LIMIT 5

  0.000985 seconds (16 allocations: 576 bytes)

5×7 DataFrames.DataFrame
...
```
"""
function query_df(sql::AbstractString, suppress_output::Bool, conn::DatabaseHandle)::DataFrames.DataFrame
  try
    result::DataFrame = if suppress_output || ( ! SearchLight.config.log_db && ! SearchLight.config.log_queries )
                          DB_ADAPTER.query(conn, sql, DataFrames.DataFrame)
                        else
                          Logger.log("SQL QUERY: $(escape_string(sql))")
                          @time DB_ADAPTER.query(conn, sql, DataFrames.DataFrame)
                        end

    if in(:num_rows_affected, names(result)) && DB_ADAPTER.insertid(conn) > 0
      DataFrame(id = DB_ADAPTER.insertid(conn))
    else
      result
    end
  catch ex
    Logger.log(string(ex), :err)
    Logger.log("MySQL error when running $(escape_string(sql))", :err)

    rethrow(ex)
  end
end


"""

"""
function query(sql::AbstractString, suppress_output::Bool, conn::DatabaseHandle)::DataStreams.Data.Rows
  try
    query = if suppress_output || ( ! SearchLight.config.log_db && ! SearchLight.config.log_queries )
              DB_ADAPTER.Query(conn, sql)
            else
              Logger.log("SQL QUERY: $(escape_string(sql))")
              @time DB_ADAPTER.Query(conn, sql)
            end

    Data.rows(query)
  catch ex
    Logger.log(string(ex), :err)
    Logger.log("MySQL error when running $(escape_string(sql))", :err)

    rethrow(ex)
  end
end


"""

"""
function relation_to_sql(m::T, rel::Tuple{SQLRelation,Symbol})::String where {T<:AbstractModel}
  rel, rel_type = rel
  j = disposable_instance(rel.model_name)
  join_table_name = j._table_name

  if rel_type == RELATION_BELONGS_TO
    j, m = m, j
  end

  (join_table_name |> Database.escape_column_name) * " ON " *
    (j._table_name |> Database.escape_column_name) * "." *
    ( (lowercase(string(typeof(m))) |> SearchLight.strip_module_name) * "_" * m._id |> Database.escape_column_name) *
    " = " *
    (m._table_name |> Database.escape_column_name) * "." *
    (m._id |> Database.escape_column_name)
end


"""

"""
function to_find_sql(m::Type{T}, q::SQLQuery, joins::Vector{SQLJoin{N}})::String where {T<:AbstractModel, N<:AbstractModel}
  sql::String = ( "$(to_select_part(m, q.columns, joins)) $(to_from_part(m)) $(to_join_part(m, joins)) $(to_where_part(m, q.where, q.scopes)) " *
                      "$(to_group_part(q.group)) $(to_having_part(q.having)) $(to_order_part(m, q.order)) " *
                      "$(to_limit_part(q.limit)) $(to_offset_part(q.offset))") |> strip
  replace(sql, r"\s+"=>" ")
end
function to_find_sql(m::Type{T}, q::SQLQuery)::String where {T<:AbstractModel}
  sql::String = ( "$(to_select_part(m, q.columns)) $(to_from_part(m)) $(to_join_part(m)) $(to_where_part(m, q.where, q.scopes)) " *
                      "$(to_group_part(q.group)) $(to_having_part(q.having)) $(to_order_part(m, q.order)) " *
                      "$(to_limit_part(q.limit)) $(to_offset_part(q.offset))") |> strip
  replace(sql, r"\s+"=>" ")
end
const to_fetch_sql = to_find_sql


"""

"""
function to_store_sql(m::T; conflict_strategy = :error)::String where {T<:AbstractModel} # upsert strateygy = :none | :error | :ignore | :update
  uf = persistable_fields(m)

  sql = if ! is_persisted(m) || (is_persisted(m) && conflict_strategy == :update)
    pos = findfirst(uf, m._id)
    pos > 0 && splice!(uf, pos)

    fields = SQLColumn(uf)
    vals = join( map(x -> string(to_sqlinput(m, Symbol(x), getfield(m, Symbol(x)))), uf), ", ")

    "INSERT INTO $(m._table_name) ( $fields ) VALUES ( $vals )" *
        if ( conflict_strategy == :error ) ""
        elseif ( conflict_strategy == :ignore ) " ON DUPLICATE KEY UPDATE `$(m._id)` = `$(m._id)`"
        elseif ( conflict_strategy == :update && ! isnull( getfield(m, Symbol(m._id)) ) )
           " ON DUPLICATE KEY UPDATE $(update_query_part(m))"
        else ""
        end
  else
    "UPDATE $(m._table_name) SET $(update_query_part(m))"
  end

  sql # * "; SELECT IF( LAST_INSERT_ID() = 0, $( isnull(getfield(m, Symbol(m._id))) ? -1 : getfield(m, Symbol(m._id)) |> Base.get ), LAST_INSERT_ID() ) AS id"
end


"""

"""
function delete_all(m::Type{T}; truncate::Bool = true, reset_sequence::Bool = true, cascade::Bool = false)::Nothing where {T<:AbstractModel}
  _m::T = m()
  truncate ? "TRUNCATE $(_m._table_name)" : "DELETE FROM $(_m._table_name)" |> SearchLight.query

  nothing
end


"""

"""
function delete(m::T)::T where {T<:AbstractModel}
  "DELETE FROM $(m._table_name) WHERE $(m._id) = '$(m.id |> Base.get)'" |> SearchLight.query

  tmp::T = T()
  m.id = tmp.id

  m
end


"""

"""
function count(m::Type{T}, q::SQLQuery = SQLQuery())::Int where {T<:AbstractModel}
  count_column = SQLColumn("COUNT(*) AS __cid", raw = true)
  q = SearchLight.clone(q, :columns, push!(q.columns, count_column))

  find_df(m, q)[1, Symbol("__cid")]
end


"""

"""
function update_query_part(m::T)::String where {T<:AbstractModel}
  update_values = join(map(x -> "$(string(SQLColumn(x))) = $( string(to_sqlinput(m, Symbol(x), getfield(m, Symbol(x)))) )", persistable_fields(m)), ", ")

  " $update_values WHERE $(m._table_name).$(m._id) = '$(Base.get(m.id))'"
end


"""

"""
function column_data_to_column_name(column::SQLColumn, column_data::Dict{Symbol,Any})::String
  "$(to_fully_qualified(column_data[:column_name], column_data[:table_name])) AS $( isempty(column_data[:alias]) ? SearchLight.to_sql_column_name(column_data[:column_name], column_data[:table_name]) : column_data[:alias] )"
end


"""

"""
function to_select_part(m::Type{T}, cols::Vector{SQLColumn}, joins = SQLJoin[])::String where {T<:AbstractModel}
  "SELECT " * Database._to_select_part(m, cols, joins)
end


"""

"""
function to_from_part(m::Type{T})::String where {T<:AbstractModel}
  "FROM " * Database.escape_column_name(m()._table_name)
end


"""

"""
function to_where_part(m::Type{T}, w::Vector{SQLWhereEntity}, scopes::Vector{Symbol})::String where {T<:AbstractModel}
  w = vcat(w, required_scopes(m)) # automatically include required scopes

  _m::T = m()
  for scope in scopes
    w = vcat(w, _m.scopes[scope])
  end

  to_where_part(w)
end
function to_where_part(w::Vector{SQLWhereEntity})::String
  where = isempty(w) ?
          "" :
          "WHERE " * (string(first(w).condition) == "AND" ? "TRUE " : "FALSE ") * join(map(wx -> string(wx), w), " ")

  replace(where, r"WHERE TRUE AND "i => "WHERE ")
end


"""

"""
function required_scopes(m::Type{T})::Vector{SQLWhereEntity} where {T<:AbstractModel}
  s = scopes(m)
  haskey(s, :required) ? s[:required] : SQLWhereEntity[]
end


"""

"""
function scopes(m::Type{T})::Dict{Symbol,Vector{SQLWhereEntity}} where {T<:AbstractModel}
  isdefined(m, :scopes) ? getfield(m()::T, :scopes) :  Dict{Symbol,Vector{SQLWhereEntity}}()
end


"""

"""
function to_order_part(m::Type{T}, o::Vector{SQLOrder})::String where {T<:AbstractModel}
  isempty(o) ?
    "" :
    "ORDER BY " * join(map(x -> (! is_fully_qualified(x.column.value) ? to_fully_qualified(m, x.column) : x.column.value) * " " * x.direction, o), ", ")
end


"""

"""
function to_group_part(g::Vector{SQLColumn})::String
  isempty(g) ?
    "" :
    " GROUP BY " * join(map(x -> string(x), g), ", ")
end


"""

"""
function to_limit_part(l::SQLLimit)::String
  l.value != "ALL" ? "LIMIT " * (l |> string) : ""
end


"""

"""
function to_offset_part(o::Int)::String
  o != 0 ? "OFFSET " * (o |> string) : ""
end


"""

"""
function to_having_part(h::Vector{SQLWhereEntity})::String
  having =  isempty(h) ?
            "" :
            "HAVING " * (string(first(h).condition) == "AND" ? "TRUE " : "FALSE ") * join(map(w -> string(w), h), " ")

  replace(having, r"HAVING TRUE AND "i => "HAVING ")
end


"""

"""
function to_join_part(m::Type{T}, joins = SQLJoin[])::String where {T<:AbstractModel}
  _m::T = m()
  join_part = ""

  for rel in relations(m)
    mr = first(rel)
    ( mr |> is_lazy ) && continue
    if ! isnull(mr.join)
      join_part *= mr.join |> Base.get |> string
    else # default
      join_part *= (mr.required ? "INNER " : "LEFT ") * "JOIN " * relation_to_sql(_m, rel)
    end
  end

  join_part * join( map(x -> string(x), joins), " " )
end


"""
    cast_type(v::Bool)::Union{Bool,Int,Char,String}

Converts the Julia type to the corresponding type in the database.
"""
function cast_type(v::Bool)::Int
  v ? 1 : 0
end


"""

"""
function create_table_sql(f::Function, name::String, options::String = "")::String
  "CREATE TABLE $name (" * join(f()::Vector{String}, ", ") * ") $options" |> strip
end


"""

"""
function column_sql(name::String, column_type::Symbol, options::String = ""; default::Any = nothing, limit::Union{Int,Nothing,String} = nothing, not_null::Bool = false)::String
  "$name $(TYPE_MAPPINGS[column_type] |> string) " *
    (isa(limit, Int) || isa(limit, String) ? "($limit)" : "") *
    (default == nothing ? "" : " DEFAULT $default ") *
    (not_null ? " NOT NULL " : "") *
    " " * options
end


"""

"""
function column_id_sql(name::String = "id", options::String = ""; constraint::String = "", nextval::String = "")::String
  "$name INT NOT NULL AUTO_INCREMENT PRIMARY KEY $options"
end


"""

"""
function add_index_sql(table_name::String, column_name::String; name::String = "", unique::Bool = false, order::Symbol = :none)::String
  name = isempty(name) ? Database.index_name(table_name, column_name) : name
  "CREATE $(unique ? "UNIQUE" : "") INDEX $(name) ON $table_name ($column_name)"
end


"""

"""
function add_column_sql(table_name::String, name::String, column_type::Symbol; default::Any = nothing, limit::Union{Int,Nothing} = nothing, not_null::Bool = false)::String
  "ALTER TABLE $table_name ADD $(column_sql(name, column_type, default = default, limit = limit, not_null = not_null))"
end


"""

"""
function drop_table_sql(name::String)::String
  "DROP TABLE $name"
end


"""

"""
function remove_column_sql(table_name::String, name::String, options::String = "")::Nothing
  "ALTER TABLE $table_name DROP COLUMN $name $options"
end


"""

"""
function remove_index_sql(table_name::String, name::String, options::String = "")::String
  "DROP INDEX $name $options"
end


"""

"""
function rand(m::Type{T}; limit = 1)::Vector{T} where {T<:AbstractModel}
  SearchLight.find(m, SQLQuery(limit = SQLLimit(limit), order = [SQLOrder("rand()", raw = true)]))
end


"""

"""
function last_insert_id(conn)
  MySQL.insertid(conn)
end

end
