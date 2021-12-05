module QueryBuilder

import SearchLight
import DataFrames

import Base: (+) #, select
# TODO: Base.isequal and Base.hash

export from, select, where, limit, offset, order, group, having, prepare

struct MissingModel <: SearchLight.AbstractModel
end

struct QueryPart{T<:SearchLight.AbstractModel}
  model::Type{T}
  query::SearchLight.SQLQuery
end


function from(model::Type{T})::QueryPart{T} where {T<:SearchLight.AbstractModel}
  QueryPart(model, SearchLight.SQLQuery())
end


function select(columns::Vararg{Union{Symbol,String,SearchLight.SQLColumn,SearchLight.SQLRaw}}) :: QueryPart
  QueryPart(MissingModel, SearchLight.SQLQuery(columns = SearchLight.SQLColumns([columns...])))
end


function where(sql_expression::String)::QueryPart
  QueryPart(MissingModel, SearchLight.SQLQuery(where = [SearchLight.SQLWhereExpression(sql_expression)]))
end
function where(sql_expression::String, values::Vararg{Any})::QueryPart
  QueryPart(MissingModel, SearchLight.SQLQuery(where = [SearchLight.SQLWhereExpression(sql_expression, [values...])]))
end


function limit(lim::Int)
  QueryPart(MissingModel, SearchLight.SQLQuery(limit = SearchLight.SQLLimit(lim)))
end


function offset(off::Int)
  QueryPart(MissingModel, SearchLight.SQLQuery(offset = off))
end


function order(ordering::Union{Symbol,String})
  QueryPart(MissingModel, SearchLight.SQLQuery(order = SearchLight.SQLOrder(ordering)))
end
function order(column::Union{Symbol,String}, direction::Union{Symbol,String})
  QueryPart(MissingModel, SearchLight.SQLQuery(order = SearchLight.SQLOrder(column, direction)))
end


function group(columns::Vararg{Union{Symbol,String}})
  QueryPart(MissingModel, SearchLight.SQLQuery(group = SearchLight.SQLColumns([columns...])))
end


function having(sql_expression::String)::QueryPart
  QueryPart(MissingModel, SearchLight.SQLQuery(having = [SearchLight.SQLWhereExpression(sql_expression)]))
end
function having(sql_expression::String, values::Vararg{Any})::QueryPart
  QueryPart(MissingModel, SearchLight.SQLQuery(having = [SearchLight.SQLWhereExpression(sql_expression, [values...])]))
end


function prepare(qb::QueryPart{T}) where {T<:SearchLight.AbstractModel}
  (qb.model::Type{T}, qb)
end
function prepare(model::Type{T}, qb::QueryPart) where {T<:SearchLight.AbstractModel}
  prepare(from(model) + qb)
end


function (+)(q::SearchLight.SQLQuery, r::SearchLight.SQLQuery)
  SearchLight.SQLQuery(
    columns = vcat(q.columns, r.columns),
    where   = vcat(q.where, r.where),
    limit   = r.limit.value == SearchLight.SQLLimit_ALL ? q.limit : r.limit,
    offset  = r.offset != 0 ? r.offset : q.offset,
    order   = vcat(q.order, r.order),
    group   = vcat(q.group, r.group),
    having  = vcat(q.having, r.having)
  )
end


function (+)(q::QueryPart, r::QueryPart)
  QueryPart(
    r.model == MissingModel ? q.model : r.model,
    q.query + r.query
  )
end


### API


function DataFrames.DataFrame(m::Type{T}, qp::QueryBuilder.QueryPart, j::Union{Nothing,Vector{SearchLight.SQLJoin}} = nothing)::DataFrames.DataFrame where {T<:SearchLight.AbstractModel}
  SearchLight.DataFrame(m, qp.query, j)
end


function SearchLight.find(m::Type{T}, qp::QueryBuilder.QueryPart,
                      j::Union{Nothing,Vector{SearchLight.SQLJoin}} = nothing)::Vector{T} where {T<:SearchLight.AbstractModel}
  SearchLight.find(m, qp.query, j)
end


function SearchLight.first(m::Type{T}, qp::QueryBuilder.QueryPart)::Union{Nothing,T} where {T<:SearchLight.AbstractModel}
  SearchLight.find(m, qp + QueryBuilder.limit(1)) |> onereduce
end


function SearchLight.last(m::Type{T}, qp::QueryBuilder.QueryPart)::Union{Nothing,T} where {T<:SearchLight.AbstractModel}
  SearchLight.find(m, qp + QueryBuilder.limit(1)) |> onereduce
end


function SearchLight.count(m::Type{T}, qp::QueryBuilder.QueryPart)::Int where {T<:SearchLight.AbstractModel}
  SearchLight.count(m, qp.query)
end


function SearchLight.sql(m::Type{T}, qp::QueryBuilder.QueryPart)::String where {T<:SearchLight.AbstractModel}
  SearchLight.sql(m, qp.query)
end

end