module QueryBuilder

using SearchLight

import Base.(+)

struct MissingModel <: SearchLight.AbstractModel
end

struct QueryPart{T<:AbstractModel}
  model::Type{T}
  query::SQLQuery
end
# QueryPart{T}(model::Type{T}, query::SQLQuery) where {T<:AbstractModel} = new(model, query)
# QueryPart{T}(model::Type{T}; query::SQLQuery = SQLQuery()) where {T<:AbstractModel} = QueryPart(model, query)
# QueryPart(; model = MissingModel, query::SQLQuery = SQLQuery()) = QueryPart(model, query)


"""
"""
function from(model::Type{T})::QueryPart{T} where {T<:AbstractModel}
  QueryPart(model, SQLQuery())
end


"""
"""
function select(columns::Vararg{Union{Symbol,String}}) :: QueryPart
  QueryPart(MissingModel, SQLQuery(columns = SQLColumns([columns...])))
end


"""
"""
function where(sql_expression::String)::QueryPart
  QueryPart(MissingModel, SQLQuery(where = [SQLWhereExpression(sql_expression)]))
end
function where(sql_expression::String, values::Vararg{Any})::QueryPart
  QueryPart(MissingModel, SQLQuery(where = [SQLWhereExpression(sql_expression, [values...])]))
end


"""
"""
function limit(lim::Int)
  QueryPart(MissingModel, SQLQuery(limit = SQLLimit(lim)))
end


"""
"""
function offset(off::Int)
  QueryPart(MissingModel, SQLQuery(offset = off))
end


"""
"""
function order(ordering::Union{Symbol,String})
  QueryPart(MissingModel, SQLQuery(order = SQLOrder(ordering)))
end
function order(column::Union{Symbol,String}, direction::Union{Symbol,String})
  QueryPart(MissingModel, SQLQuery(order = SQLOrder(column, direction)))
end


"""
"""
function group(columns::Vararg{Union{Symbol,String}})
  QueryPart(MissingModel, SQLQuery(group = SQLColumns([columns...])))
end


"""
"""
function having(sql_expression::String)::QueryPart
  QueryPart(MissingModel, SQLQuery(having = [SQLWhereExpression(sql_expression)]))
end
function having(sql_expression::String, values::Vararg{Any})::QueryPart
  QueryPart(MissingModel, SQLQuery(having = [SQLWhereExpression(sql_expression, [values...])]))
end


"""
"""
function scopes(scopes::Vector{Symbol})::QueryPart
  QueryPart(MissingModel, SQLQuery(scopes = scopes))
end


"""
"""
function prepare(qb::QueryPart)
  (qb.model, qb.query)
end
function prepare(model::Type{T}, qb::QueryPart) where {T<:AbstractModel}
  prepare(from(model) + qb)
end

function (+)(q::SQLQuery, r::SQLQuery)
  SQLQuery(
    columns = vcat(q.columns, r.columns),
    where   = vcat(q.where, r.where),
    limit   = r.limit.value == SQLLimit_ALL ? q.limit : r.limit,
    offset  = r.offset != 0 ? r.offset : q.offset,
    order   = vcat(q.order, r.order),
    group   = vcat(q.group, r.group),
    having  = vcat(q.having, r.having),
    scopes  = vcat(q.scopes, r.scopes)
  )
end


"""
"""
function (+)(q::QueryPart, r::QueryPart)
  QueryPart(
    r.model == MissingModel ? q.model : r.model,
    q.query + r.query
  )
end

end
