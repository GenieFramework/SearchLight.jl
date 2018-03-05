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
function query(model::Type{T}) where {T<:AbstractModel}
  QueryPart(model)
end


"""
"""
function select(columns)
  QueryPart(MissingModel, SQLQuery(columns = ))
end

end
