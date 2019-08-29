import Base.string
import Base.print
import Base.show
import Base.convert
import Base.length
import Base.==

using Dates, Reexport
@reexport using Nullables

export DbId, SQLType, AbstractModel, ModelValidator
export SQLInput, SQLColumn, SQLColumns, SQLLogicOperator
export SQLWhere, SQLWhereExpression, SQLWhereEntity, SQLLimit, SQLOrder, SQLQuery, SQLRaw
export SQLRelation, SQLRelationData
export SQLJoin, SQLOn, SQLJoinType, SQLHaving, SQLScope

export is_lazy, @sql_str

abstract type SearchLightAbstractType end
abstract type SQLType <: SearchLightAbstractType end
abstract type AbstractModel <: SearchLightAbstractType end

string(io::IO, t::T) where {T<:SearchLightAbstractType} = "$(typeof(t)) <: $(supertype(typeof(t)))"
print(io::IO, t::T) where {T<:SearchLightAbstractType} = print(io, "$(typeof(t)) <: $(supertype(typeof(t)))")
show(io::IO, t::T) where {T<:SearchLightAbstractType} = print(io, searchlightabstracttype_to_print(t))

"""
    searchlightabstracttype_to_print{T<:SearchLightAbstractType}(m::T) :: String

Pretty printing of SearchLight types.
"""
function searchlightabstracttype_to_print(m::T) :: String where {T<:SearchLightAbstractType}
  output = "\n" * "$(typeof(m))" * "\n"
  output *= string(Millboard.table(to_string_dict(m))) * "\n"

  output
end

const DbId = Nullable{Union{Int32,Int64,String}}

convert(::Type{Nullable{DbId}}, v::Number) = Nullable{DbId}(DbId(v))
convert(::Type{Nullable{DbId}}, v::String) = Nullable{DbId}(DbId(v))

Base.show(io::IO, dbid::DbId) = print(io, (isnull(dbid) ? "NULL" : string(Base.get(dbid))))


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
SQLInput(a::Date) = string(a) |> SQLInput
SQLInput(a::Vector{T}) where {T} = map(x -> SQLInput(x), a)
SQLInput(s::SubString{T}) where {T} = convert(String, s) |> SQLInput
SQLInput(i::SQLInput) = i
SQLInput(s::Symbol) = string(s) |> SQLInput
SQLInput(r::SQLRaw) = SQLInput(r.value, raw = true)
SQLInput(a::Any) = string(a) |> SQLInput
SQLInput(n::Nullable) = isnull(n) ? SQLInput(nothing) : SQLInput(get(n))

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
convert(::Type{SQLInput}, d::DateTime) = SQLInput(string(d))
convert(::Type{SQLInput}, d::Dates.Date) = SQLInput(string(d))
convert(::Type{SQLInput}, d::Dates.Time) = SQLInput(string(d))
function convert(::Type{SQLInput}, n::Nullable{T}) where {T}
  if isnull(n)
    SQLInput("NULL", escaped = true, raw = true)
  else
    Base.get(n) |> SQLInput
  end
end


"""
    escape_value(i::SQLInput)

Sanitizes input to be used as values in SQL queries.
"""
function escape_value(i::SQLInput) :: SQLInput
  (i.value == "NULL" || i.value == "NOT NULL") && return i

  if ! i.escaped && ! i.raw
    i.value = Database.escape_value(i.value)
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
function escape_column_name(s::String) :: String
  join(
    map(
      x -> Database.escape_column_name(string(x))
      , split(s, ".")
    )
    , ".")
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
function string(w::SQLWhere, m::T) where {T <: AbstractModel}
  w.column = SQLColumn(w.column.value, escaped = w.column.escaped, raw = w.column.raw, table_name = m._table_name)
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

  function SQLWhereExpression(sql_expression::String, values::Vector{SQLInput})
    condition = "AND"
    parts = split(sql_expression, " ")
    if in(parts[1], ["AND", "OR", "and", "or"])
      condition = parts |> first |> uppercase
      sql_expression = parts[2:end] |> strip
    end

    new(sql_expression, values, condition)
  end
end
SQLWhereExpression(sql_expression::String, values...) = SQLWhereExpression(sql_expression, [values...])
SQLWhereExpression(sql_expression::String) = SQLWhereExpression(sql_expression, SQLInput[])
SQLWhereExpression(sql_expression::String, values::Dates.Date) = SQLWhereExpression(sql_expression, [SQLInput(string(values))])
SQLWhereExpression(sql_expression::String, values::Vector{T}) where {T} = SQLWhereExpression(sql_expression, SQLInput(values))
SQLWhereExpression(sql_expression::String, values::T) where {T} = SQLWhereExpression(sql_expression, [SQLInput(values)])

function string(we::SQLWhereExpression)
  string_value = we.sql_expression

  # look for column placeholders, indicated by : -- such as :id
  # column_placeholders = matchall(r":[a-zA-Z0-9_-]*", string_value)
  for pl in collect((m.match for m = eachmatch(r":[a-zA-Z0-9_-]*", string_value)))
    string_value = replace(string_value, pl => SQLColumn(string(pl[2:end])))
  end

  # replace value placeholders, indicated by ?
  counter = 0
  string_value = replace(string_value, "\\?"=>"\\§\\")
  while something(findfirst(isequal('?'), string_value), 0) > 0 # search(string_value, '?') > 0
    counter += 1
    counter > size(we.values, 1) && throw("Not enough replacement values")

    string_value = replace(string_value, "?" => string(we.values[counter]), count = 1)
  end
  string_value = replace(string_value, "\\§\\" => "?")

  we.condition * " " * string_value
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


"""
Wrapper around SQL `limit` operator.
"""
struct SQLLimit <: SQLType
  value::Union{Int, String}
  SQLLimit(v::Int) = new(v)
  function SQLLimit(v::String)
    v = strip(uppercase(v))
    if v == SQLLimit_ALL
      return new(SQLLimit_ALL)
    else
      i = tryparse(Int, v)
      if isnull(i)
        error("Can't parse SQLLimit value")
      else
        return new(Base.get(i))
      end
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

#
# SQLJoin - SQLJoinType
#


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
      error("""Invalid join type - accepted options are $(join(accepted_values, ", "))""")
      new("INNER")
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
  on::SQLOn
  join_type::SQLJoinType
  outer::Bool
  where::Vector{SQLWhereEntity}
  natural::Bool
  columns::Vector{SQLColumns}
end
SQLJoin(model_name::Type{T},
        on::SQLOn;
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
  _m = j.model_name()
  sql = """ $(j.natural ? "NATURAL " : "") $(string(j.join_type)) $(j.outer ? "OUTER " : "") JOIN $(Util.add_quotes(_m._table_name)) $(string(j.on)) """
  sql *=  if ! isempty(j.where)
          SearchLight.to_where_part(j.where)
        else
          ""
        end

  sql
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
              having  = SQLWhereEntity[],
              scopes  = Symbol[] )

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
|  scopes |                                                     Symbol[] |
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
  scopes::Vector{Symbol}

  SQLQuery(;  columns = SQLColumn[], where = SQLWhereEntity[], limit = SQLLimit("ALL"), offset = 0,
              order = SQLOrder[], group = SQLColumn[], having = SQLWhereEntity[], scopes = Symbol[]) =
    new(columns, where, limit, offset, order, group, having, scopes)
end

string(q::SQLQuery, m::Type{T}) where {T<:AbstractModel} = to_fetch_sql(m, q)


#
# SQLRelation
#

"""
Represents the data contained by a SQL relation.
"""
mutable struct SQLRelationData{T<:AbstractModel} <: SQLType
  collection::Vector{T}

  SQLRelationData{T}(collection::Vector{T}) where {T<:AbstractModel} = new(collection)
end
SQLRelationData(collection::Vector{T}) where {T<:AbstractModel} = SQLRelationData{T}(collection)
SQLRelationData(m::T) where {T<:AbstractModel} = SQLRelationData{T}([m])


"""
Defines the relation between two models, as reflected by the relation of their underlying SQL tables.
"""
mutable struct SQLRelation{T<:AbstractModel} <: SQLType
  model_name::Type{T}
  eagerness::Symbol
  data::Nullable{SQLRelationData}
  join::Nullable{SQLJoin}
  where::Nullable{SQLWhereEntity}

  SQLRelation{T}(model_name::Type{T}, eagerness, data, join, where) where {T<:AbstractModel} = new(model_name, eagerness, data, join, where)
end
SQLRelation(model_name::Type{T};
            eagerness = RELATION_EAGERNESS_LAZY,
            data = Nullable{SQLRelationData}(),
            join = Nullable{SQLJoin}(),
            where = Nullable{SQLWhereEntity}()) where {T<:AbstractModel} = SQLRelation{T}(model_name, eagerness, data, join, where)

function lazy(r::SQLRelation)
  r.eagerness == RELATION_EAGERNESS_LAZY
end
function is_lazy(r::SQLRelation)
  lazy(r)
end
