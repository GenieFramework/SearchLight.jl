import Base.string
import Base.print
import Base.show
import Base.convert
import Base.length
import Base.==
import Base.hash

import Dates

export DbId, SQLType, AbstractModel
export SQLInput, SQLColumn, SQLColumns, SQLLogicOperator
export SQLWhere, SQLWhereExpression, SQLWhereEntity, SQLLimit, SQLOrder, SQLQuery, SQLRaw
export SQLJoin, SQLOn, SQLJoinType, SQLHaving

export @sql_str

abstract type SearchLightAbstractType end
abstract type SQLType <: SearchLightAbstractType end

abstract type AbstractModel <: SearchLightAbstractType end

function hash(a::T) where {T<:AbstractModel}
  Base.hash(string(typeof(a)) * string(getfield(a, pk(a) |> Symbol)))
end

function ==(a::A, b::B) where {A<:AbstractModel,B<:AbstractModel}
  hash(a) == hash(b)
end

function Base.print(io::IO, t::T) where {T<:SearchLightAbstractType}
  props = []
  for (k,v) in to_string_dict(t)
    push!(props, "$k=$v")
  end
  print(io, string("$(typeof(t))(", join(props, ','), ")"))
end

Base.show(io::IO, t::T) where {T<:SearchLightAbstractType} = print(io, searchlightabstracttype_to_print(t))

"""
    searchlightabstracttype_to_print{T<:SearchLightAbstractType}(m::T) :: String

Pretty printing of SearchLight types.
"""
function searchlightabstracttype_to_print(m::T) :: String where {T<:SearchLightAbstractType}
  string(typeof(m), "\n", Millboard.table(to_string_dict(m)), "\n")
end

mutable struct DbId
  value::Union{Nothing,Int,String}
end
DbId() = DbId(nothing)
DbId(id::Number) = DbId(Int(id))
DbId(id::AbstractString) = DbId(id)

function hash(a::DbId)
  Base.hash(a.value)
end

function ==(a::DbId, b::DbId)
  hash(a) == hash(b)
end

Base.convert(::Type{DbId}, v::Union{Number,String}) = DbId(v)
Base.convert(::Type{DbId}, v::Nothing) = DbId(nothing)

Base.convert(::Type{String}, id::DbId) = string(id.value)
Base.convert(::Type{Union{Int,String}}, v::DbId) = v.value

Base.show(io::IO, dbid::DbId) = print(io, (dbid.value === nothing ? "NULL" : string(dbid.value)))


#
# SQLRaw
#


"""
Wrapper around a raw SQL query part.
"""
struct SQLRaw <: SQLType
  value::String
end

macro sql_str(q)
  SQLRaw(q)
end

string(io::IO, t::SQLRaw) = t.value

#
# SQLInput
#


"""
Provides safe input into SQL queries and operations related to that.
"""
mutable struct SQLInput <: SQLType
  value::Union{String,Real}
  escaped::Bool
  raw::Bool
  SQLInput(v::Union{String,Real}; escaped = false, raw = false) = new(v, escaped, raw)
end
SQLInput(a::Dates.Date) = string(a) |> SQLInput
SQLInput(a::Vector{T}) where {T} = map(x -> SQLInput(x), a)
SQLInput(s::SubString{T}) where {T} = convert(String, s) |> SQLInput
SQLInput(i::SQLInput) = i
SQLInput(s::Symbol) = string(s) |> SQLInput
SQLInput(r::SQLRaw) = SQLInput(r.value, raw = true)
SQLInput(n::Nothing) = SQLInput("NULL", escaped = true, raw = true)
SQLInput(a::Any) = string(a) |> SQLInput

==(a::SQLInput, b::SQLInput) = a.value == b.value

string(s::SQLInput) = "$(safe(s).value)"
string(a::Vector{SQLInput}) = join(map(x -> string(x), a), ",")
endof(s::SQLInput) = endof(s.value)
length(s::SQLInput) = length(s.value)
next(s::SQLInput, i::Int) = next(s.value, i)
safe(s::SQLInput) = escape_value(s)

print(io::IO, s::SQLInput) = print(io, string(s))
show(io::IO, s::SQLInput) = print(io, string(s))

convert(::Type{SQLInput}, r::Real) = SQLInput(parse(r))
convert(::Type{SQLInput}, s::Symbol) = SQLInput(string(s))
convert(::Type{SQLInput}, d::Dates.DateTime) = SQLInput(string(d))
convert(::Type{SQLInput}, d::Dates.Date) = SQLInput(string(d))
convert(::Type{SQLInput}, d::Dates.Time) = SQLInput(string(d))
convert(::Type{SQLInput}, id::DbId) = SQLInput(id.value)


"""
    escape_value(i::SQLInput)

Sanitizes input to be used as values in SQL queries.
"""
function escape_value(i::SQLInput) :: SQLInput
  (i.value == "NULL" || i.value == "NOT NULL") && return i

  if ! i.escaped && ! i.raw
    i.value = SearchLight.escape_value(i.value)
    i.escaped = true
  end

  return i
end


#
# SQLColumn
#


"""
Represents a SQL column when building SQL queries.
"""
mutable struct SQLColumn <: SQLType
  value::String
  escaped::Bool
  raw::Bool
  table_name::String
  column_name::String
end
SQLColumn(v::Union{String,Symbol}; escaped = false, raw = false, table_name = "", column_name = "") = begin
  v = string(v)
  v == "*" && (raw = true)
  is_fully_qualified(v) && ((table_name, v) = from_fully_qualified(v))

  SQLColumn(string(v), escaped, raw, string(table_name), string(v))
end
SQLColumn(a::Array) = map(x -> SQLColumn(x), a)
SQLColumn(c::SQLColumn) = c
SQLColumn(r::SQLRaw) = SQLColumn(r.value, raw = true)
SQLColumn(a::Any) = SQLColumn(string(a))

==(a::SQLColumn, b::SQLColumn) = a.value == b.value

string(a::Vector{SQLColumn}) = join(map(x -> string(x), a), ", ")
string(s::SQLColumn) = safe(s).value
safe(s::SQLColumn) = escape_column_name(s)

convert(::Type{SQLColumn}, s::Symbol) = SQLColumn(string(s))
convert(::Type{SQLColumn}, s::String) = SQLColumn(s)
convert(::Type{SQLColumn}, v::String, e::Bool, r::Bool) = SQLColumn(v, escaped = e, raw = r)
convert(::Type{SQLColumn}, v::String, e::Bool, r::Bool, t::Any) = SQLColumn(v, escaped = e, raw = r, table_name = string(t))

print(io::IO, a::Vector{SQLColumn}) = print(io, string(a))
show(io::IO, a::Vector{SQLColumn}) = print(io, string(a))
print(io::IO, s::SQLColumn) = print(io, string(s))
show(io::IO, s::SQLColumn) = print(io, string(s))

const SQLColumns = SQLColumn # so we can use both


"""
    escape_column_name(c::SQLColumn) :: SQLColumn
    escape_column_name(s::String)

Sanitizes input to be use as column names in SQL queries.
"""
function escape_column_name(c::SQLColumn) :: SQLColumn
  if ! c.escaped && ! c.raw
    c.column_name = isempty(c.column_name) && is_fully_qualified(c.value) ? from_fully_qualified(c.value)[2] : c.value
    val = ! isempty(c.table_name) && ! startswith(c.value, (c.table_name * ".")) && ! is_fully_qualified(c.value) ? c.table_name * "." * c.value : c.value
    c.value = escape_column_name(val)
    c.escaped = true

  end

  c
end


#
# SQLLogicOperator
#


"""
Represents the logic operators (OR, AND) as part of SQL queries.
"""
struct SQLLogicOperator <: SQLType
  value::String
  SQLLogicOperator(v::String) = new( v == "OR" ? "OR" : "AND" )
end
SQLLogicOperator(v::Any) = SQLLogicOperator(string(v))
SQLLogicOperator() = SQLLogicOperator("AND")

string(s::SQLLogicOperator) = s.value

#
# SQLWhere
#


"""
Provides functionality for building and manipulating SQL `WHERE` conditions.
"""
struct SQLWhere <: SQLType
  column::SQLColumn
  value::SQLInput
  condition::SQLLogicOperator
  operator::String

  SQLWhere(column::SQLColumn, value::SQLInput, condition::SQLLogicOperator, operator::String) =
    new(column, value, condition, operator)
end
SQLWhere(column::Any, value::Any, condition::Any, operator::String) = SQLWhere(SQLColumn(column), SQLInput(value), SQLLogicOperator(condition), operator)
SQLWhere(column::SQLColumn, value::SQLInput, operator::String) = SQLWhere(column, value, SQLLogicOperator("AND"), operator)
SQLWhere(column::SQLColumn, value::SQLInput, condition::SQLLogicOperator) = SQLWhere(column, value, condition, "=")
SQLWhere(column::Any, value::Any, operator::Any) = SQLWhere(SQLColumn(column), SQLInput(value), SQLLogicOperator("AND"), operator)
SQLWhere(column::SQLColumn, value::SQLInput) = SQLWhere(column, value, SQLLogicOperator("AND"))
SQLWhere(column::Any, value::Any) = SQLWhere(SQLColumn(column), SQLInput(value))

string(w::SQLWhere) = "$(w.condition.value) ($(w.column) $(w.operator) $(enclosure(w.value, w.operator)))"
function string(w::SQLWhere, m::Type{T}) where {T <: AbstractModel}
  w.column = SQLColumn(w.column.value, escaped = w.column.escaped, raw = w.column.raw, table_name = table(m))
  "$(w.condition.value) ($(w.column) $(w.operator) $(enclosure(w.value, w.operator)))"
end
print(io::IO, w::T) where {T<:SQLWhere} = print(io, searchlightabstracttype_to_print(w))
show(io::IO, w::T) where {T<:SQLWhere} = print(io, searchlightabstracttype_to_print(w))

convert(::Type{Vector{SQLWhere}}, w::SQLWhere) = [w]

#
# SQLWhereExpression
#

"""
    SQLWhereExpression(sql_expression::String, values::T)
    SQLWhereExpression(sql_expression::String[, values::Vector{T}])

Constructs an instance of SQLWhereExpression, replacing the `?` placeholders inside `sql_expression` with
properly quoted values.

# Examples:
```julia
julia> SQLWhereExpression("slug LIKE ?", "%julia%")

SearchLight.SQLWhereExpression
+================+=============+
|            key |       value |
+================+=============+
|      condition |         AND |
+----------------+-------------+
| sql_expression | slug LIKE ? |
+----------------+-------------+
|         values |   '%julia%' |
+----------------+-------------+

julia> SQLWhereExpression("id BETWEEN ? AND ?", [10, 20])

SearchLight.SQLWhereExpression
+================+====================+
|            key |              value |
+================+====================+
|      condition |                AND |
+----------------+--------------------+
| sql_expression | id BETWEEN ? AND ? |
+----------------+--------------------+
|         values |              10,20 |
+----------------+--------------------+

julia> SQLWhereExpression("question LIKE 'what is the question\\?'")

SearchLight.SQLWhereExpression
+================+========================================+
|            key |                                  value |
+================+========================================+
|      condition |                                    AND |
+----------------+----------------------------------------+
| sql_expression | question LIKE 'what is the question?'  |
+----------------+----------------------------------------+
|         values |                                        |
+----------------+----------------------------------------+
```
"""
struct SQLWhereExpression <: SQLType
  sql_expression::String
  values::Vector{SQLInput}
  condition::String
end

const QUESTION_MARK_REPLACEMENT = "&QM;"

function SQLWhereExpression(sql_expression::String, values::Vector{SQLInput})
  condition = "AND"

  parts = split(sql_expression, " ")
  if in(parts[1], ["AND", "OR", "and", "or"])
    condition = parts |> first |> uppercase
    sql_expression = parts[2:end] |> strip
  end

  SQLWhereExpression(sql_expression, [SQLInput(isa(v.value, AbstractString) ? replace(v.value, "?" => QUESTION_MARK_REPLACEMENT) : v.value) for v in values], condition)
end

SQLWhereExpression(sql_expression::String, values...) = SQLWhereExpression(sql_expression, [values...])
SQLWhereExpression(sql_expression::String) = SQLWhereExpression(sql_expression, SQLInput[])
SQLWhereExpression(sql_expression::String, values::Dates.Date) = SQLWhereExpression(sql_expression, [SQLInput(string(values))])
SQLWhereExpression(sql_expression::String, values::Vector{T}) where {T} = SQLWhereExpression(sql_expression, SQLInput(values))
SQLWhereExpression(sql_expression::String, values::T) where {T} = SQLWhereExpression(sql_expression, [SQLInput(values)])

function string(we::SQLWhereExpression)
  string_value = we.sql_expression

  for pl in (m.match for m = eachmatch(r":[a-zA-Z0-9_-]*", string_value))
    string_value = replace(string_value, pl => SQLColumn(string(pl[2:end])))
  end

  counter = 1
  result = string_value
  pos = 0
  while ( pos = something(findnext(isequal('?'), string_value, pos+1), 0) ) > 0
    result = replace(result, '?'=>string(we.values[counter]), count = 1)

    counter += 1
  end

  result = replace(result, QUESTION_MARK_REPLACEMENT => '?')

  string(we.condition, " ", result)
end

const SQLWhereEntity = Union{SQLWhere,SQLWhereExpression}
const SQLHaving = Union{SQLWhere,SQLWhereExpression}

convert(::Type{Vector{SQLWhereEntity}}, s::String) = SQLWhereEntity[SQLWhereExpression(s)]
convert(::Type{SQLWhereEntity}, s::String) = SQLWhereExpression(s);


#
# SQLLimit
#


const SQLLimit_ALL = "ALL"
export SQLLimit_ALL

struct UnparsableSQLLimitException <: Exception
  value
end
Base.showerror(io::IO, e::UnparsableSQLLimitException) = print(io, "Can't parse SQLLimit value $(e.value)")

"""
Wrapper around SQL `limit` operator.
"""
struct SQLLimit <: SQLType
  value::Union{Int,String}
  SQLLimit(v::Int) = new(v)

  function SQLLimit(v::String)
    v = strip(uppercase(v))
    if v == SQLLimit_ALL
      return new(SQLLimit_ALL)
    else
      i = tryparse(Int, v)
      i === nothing ? throw(UnparsableSQLLimitException(v)) : i
    end
  end
end
SQLLimit() = SQLLimit(SQLLimit_ALL)

string(l::SQLLimit) = string(l.value)

convert(::Type{SQLLimit}, v::Int) = SQLLimit(v)

#
# SQLOrder
#


"""
Wrapper around SQL `order` operator.
"""
struct SQLOrder <: SQLType
  column::SQLColumn
  direction::String
  SQLOrder(column::SQLColumn, direction::String) =
    new(column, uppercase(string(direction)) == "DESC" ? "DESC" : "ASC")
end
SQLOrder(column::Union{String,Symbol}, direction::Any; raw::Bool = false) = SQLOrder(SQLColumn(column, raw = raw), string(direction))
function SQLOrder(s::Union{String,Symbol}; raw::Bool = false)
  s = String(s)

  if endswith(rstrip(uppercase(s)), " ASC") || endswith(rstrip(uppercase(s)), " DESC")
    parts = split(s, " ")
    SQLOrder(String(parts[1]), String(parts[2]), raw = raw)
  else
    SQLOrder(s, "ASC", raw = raw)
  end
end
SQLOrder(r::SQLRaw, direction::Any = "ASC") = SQLOrder(r.value, direction, raw = true)

string(o::SQLOrder) = "($(o.column) $(o.direction))"

convert(::Type{SQLOrder}, s::String) = SQLOrder(s)
convert(::Type{Vector{SQLOrder}}, o::SQLOrder) = [o]
convert(::Type{Vector{SQLOrder}}, s::Symbol) = [SQLOrder(s)]
convert(::Type{Vector{SQLOrder}}, s::String) = [SQLOrder(s)]
convert(::Type{Vector{SQLOrder}}, t::Tuple{Symbol,Symbol}) = [SQLOrder(t[1], t[2])]

#
# SQLJoin
#

#
# SQLJoin - SQLOn
#


"""
Represents the `ON` operator used in SQL `JOIN`
"""
struct SQLOn <: SQLType
  column_1::SQLColumn
  column_2::SQLColumn
  conditions::Vector{SQLWhereEntity}

  SQLOn(column_1, column_2; conditions = SQLWhereEntity[]) = new(column_1, column_2, conditions)
end
function string(o::SQLOn)
  on = " ON $(o.column_1) = $(o.column_2) "
  if ! isempty(o.conditions)
    on *= " AND " * join( map(x -> string(x), o.conditions), " AND " )
  end

  on
end

convert(::Type{Vector{SQLOn}}, j::SQLOn) = [j]

#
# SQLJoin - SQLJoinType
#

struct InvalidJoinTypeException <: Exception
  jointype::String
end

Base.showerror(io::IO, e::InvalidJoinTypeException) = print(io, "Invalid join type $(e.jointype)")

"""
Wrapper around the various types of SQL `join` (`left`, `right`, `inner`, etc).
"""
struct SQLJoinType <: SQLType
  join_type::String

  function SQLJoinType(t::Union{String,Symbol})
    t = string(t)
    accepted_values = ["inner", "INNER", "left", "LEFT", "right", "RIGHT", "full", "FULL"]
    if in(t, accepted_values)
      new(uppercase(t))
    else
      @error  """Accepted JOIN types are $(join(accepted_values, ", "))"""
      throw(InvalidJoinTypeException(t))
    end
  end
end

convert(::Type{SQLJoinType}, s::Union{String,Symbol}) = SQLJoinType(s)

string(jt::SQLJoinType) = jt.join_type

#
# SQLJoin
#


"""
Builds and manipulates SQL `join` expressions.
"""
struct SQLJoin{T<:AbstractModel} <: SQLType
  model_name::Type{T}
  on::Vector{SQLOn}
  join_type::SQLJoinType
  outer::Bool
  where::Vector{SQLWhereEntity}
  natural::Bool
  columns::Vector{SQLColumns}
end

SQLJoin(model_name::Type{T},
        on::Vector{SQLOn};
        join_type = SQLJoinType("INNER"),
        outer = false,
        where = SQLWhereEntity[],
        natural = false,
        columns = SQLColumns[]) where {T<:AbstractModel} = SQLJoin{T}(model_name, on, join_type, outer, where, natural, columns)

SQLJoin(model_name::Type{T},
        on_column_1::Union{String,SQLColumn},
        on_column_2::Union{String,SQLColumn};
        join_type = SQLJoinType("INNER"),
        outer = false,
        where = SQLWhereEntity[],
        natural = false,
        columns = SQLColumns[]) where {T<:AbstractModel} = SQLJoin(model_name, SQLOn(on_column_1, on_column_2), join_type = join_type, outer = outer, where = where, natural = natural, columns = columns)

function string(j::SQLJoin)
  sql = """ $(j.natural ? "NATURAL " : "") $(string(j.join_type)) $(j.outer ? "OUTER " : "") JOIN $( escape_column_name(table(j.model_name), SearchLight.connection())) $(join(string.(j.on), " AND ")) """
  sql *=  if ! isempty(j.where)
          SearchLight.to_where_part(j.where)
        else
          ""
        end

  sql = replace(sql, "  " => " ")

  replace(sql, " AND ON " => " AND ")
end

convert(::Type{Vector{SQLJoin}}, j::SQLJoin) = [j]


#
# SQLQuery
#

"""
    SQLQuery( columns = SQLColumn[],
              where   = SQLWhereEntity[],
              limit   = SQLLimit("ALL"),
              offset  = 0,
              order   = SQLOrder[],
              group   = SQLColumn[],
              having  = SQLWhereEntity[])

Returns a new instance of SQLQuery.

# Examples
```julia
julia> SQLQuery(where = [SQLWhereExpression("id BETWEEN ? AND ?", [10, 20])], offset = 5, limit = 5, order = :title)

SearchLight.SQLQuery
+=========+==============================================================+
|     key |                                                        value |
+=========+==============================================================+
| columns |                                                              |
+---------+--------------------------------------------------------------+
|   group |                                                              |
+---------+--------------------------------------------------------------+
|  having | Union{SearchLight.SQLWhere,SearchLight.SQLWhereExpression}[] |
+---------+--------------------------------------------------------------+
|   limit |                                                            5 |
+---------+--------------------------------------------------------------+
|  offset |                                                            5 |
+---------+--------------------------------------------------------------+
|         |                                        SearchLight.SQLOrder[ |
|         |                                         SearchLight.SQLOrder |
|         |                                      +===========+=========+ |
|         |                                      |       key |   value | |
|   order |                                                 +========... |
+---------+--------------------------------------------------------------+
|         |  Union{SearchLight.SQLWhere,SearchLight.SQLWhereExpression}[ |
|         |                               SearchLight.SQLWhereExpression |
|   where |                                                 +========... |
+---------+--------------------------------------------------------------+
```
"""
mutable struct SQLQuery <: SQLType
  columns::Vector{SQLColumn}
  where::Vector{SQLWhereEntity}
  limit::SQLLimit
  offset::Int
  order::Vector{SQLOrder}
  group::Vector{SQLColumn}
  having::Vector{SQLWhereEntity}

  SQLQuery(;  columns = SQLColumn[], where = SQLWhereEntity[], limit = SQLLimit("ALL"), offset = 0,
              order = SQLOrder[], group = SQLColumn[], having = SQLWhereEntity[]) =
    new(columns, where, limit, offset, order, group, having)
end

string(q::SQLQuery, m::Type{T}) where {T<:AbstractModel} = to_fetch_sql(m, q)