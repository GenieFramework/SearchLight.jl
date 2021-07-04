module Relationships

using Inflector
using SearchLight
using SearchLight.Migration


export Relationship, Relationship!, related, isrelated


function create_relationship_migration(r1::Type{T}, r2::Type{R})::String where {T<:AbstractModel, R<:AbstractModel}
  names = map(x -> split(string(x), '.')[end] |> string |> lowercase |> Inflector.to_plural, [r1, r2]) |> sort
  Migration.new_relationship_table("create_relationship_table_$(names[1])_$(names[2])", names...)
end


function relationship_name(r1::Type{T}, r2::Type{R})::String where {T<:AbstractModel, R<:AbstractModel}
  map(x -> split(string(x), '.')[end] |> string |> Inflector.to_plural, [r1, r2]) |> sort |> join
end


function relationship_field_name(x::Type{T})::String where {T<:AbstractModel}
  (split(string(x), '.')[end] |> string |> lowercase |> Inflector.to_plural) * "_id"
end


function Relationship(r1::Type{T}, r2::Type{R}; context::Module = @__MODULE__)::DataType where {T<:AbstractModel, R<:AbstractModel}
  isdefined(context, Symbol(relationship_name(r1, r2))) &&
    return getfield(context, Symbol(relationship_name(r1, r2)))

  struct_str = "mutable struct $(relationship_name(r1, r2)) <: AbstractModel;
                  id::DbId;
                  $(relationship_field_name(r1))::DbId;
                  $(relationship_field_name(r2))::DbId;
                end"

  Core.eval(context, Meta.parse(struct_str))

  kwd_constructor_str = "$(relationship_name(r1, r2))(; id::DbId = DbId(), $(relationship_field_name(r1))::DbId = DbId(), $(relationship_field_name(r2))::DbId = DbId()) = $(relationship_name(r1, r2))(id, $(relationship_field_name(r1)), $(relationship_field_name(r2)))"

  Core.eval(context, Meta.parse(kwd_constructor_str))

  getfield(context, Symbol(relationship_name(r1, r2)))
end


function Relationship!(r1::T, r2::R; context::Module = @__MODULE__)::AbstractModel where {T<:AbstractModel, R<:AbstractModel}
  relationship = Relationship(typeof(r1), typeof(r2); context = context)

  findone_or_create(relationship;
                    NamedTuple{ (Symbol(relationship_field_name(typeof(r1))), Symbol(relationship_field_name(typeof(r2)))) }(
                      (getfield(r1, pk(r1) |> Symbol), getfield(r2, pk(r2) |> Symbol)) )...) |> save!
end


function related(m::T, r::Type{R}; through::Vector = [], context::Module = @__MODULE__)::Vector{R} where {T<:AbstractModel, R<:AbstractModel}
  joins = SQLJoin[]
  models = vcat(typeof(m), through, r) |> pairs

  for i in length(models):-1:2
    relationship = Relationship(models[i], models[i-1]; context = context)

    push!(joins, SQLJoin(relationship,
                        [
                          SQLOn("$(SearchLight.table(models[i])).$(pk(models[i]))",
                              "$(SearchLight.table(relationship)).$(relationship_field_name(models[i]))")
                        ]
                        ))

  push!(joins, SQLJoin(models[i-1],
                        [
                          SQLOn("$(SearchLight.table(models[i-1])).$(pk(models[i-1]))",
                              "$(SearchLight.table(relationship)).$(relationship_field_name(models[i-1]))")
                        ]
                        ))
  end

  find(r, SQLQuery(
    where = SQLWhereEntity[SQLWhereExpression("$(SearchLight.table(typeof(m))).$(pk(m)) = ?", SQLInput[getfield(m, Symbol(pk(m)))])],
  ), joins)
end


function isrelated(m::T, r::R; through::Vector = [], context::Module = @__MODULE__)::Bool where {T<:AbstractModel, R<:AbstractModel}
  r in related(m, typeof(r), through = through)
end


end