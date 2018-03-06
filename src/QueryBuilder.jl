module QueryBuilder

using SearchLight

struct MissingModel <: AbstractModel
end

mutable struct QueryPart{T<:AbstractModel}
  model::Type{T}
  query::SQLQuery

  QueryPart(model::Type{T}, query::SQLQuery) where {T<:AbstractModel} = new(model, query)
end
QueryPart(model::Type{T}; query::SQLQuery = SQLQuery()) where {T<:AbstractModel} = QueryPart(model, query)
QueryPart(; model::Type{T} = MissingModel, query::SQLQuery = SQLQuery()) where {T<:AbstractModel} = QueryPart(model, query)


"""
"""
function from(model::Type{T})::QueryPart where {T<:AbstractModel}
  QueryPart(model)
end


"""
"""
function select(columns::Vector) :: QueryPart
  QueryPart(MissingModel, SQLQuery(columns = SQLColumns(columns)))
end


"""
"""
function where(sql_expression::String, values::Vector{T} = T[])::QueryPart where {T}
  QueryPart(MissingModel, SQLQuery(where = SQLWhereExpression(sql_expression, values)))
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
function prepare(qb::QueryBuilder)
  (qb.model, qb.query)
end
