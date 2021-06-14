module Relationships

using Base: invokelatest, NamedTuple
using Inflector
using SearchLight
using SearchLight.Migration


function create_relationship_migration(r1::Type{T}, r2::Type{R})::String where {T<:AbstractModel, R<:AbstractModel}
  names = map(x -> string(x) |> lowercase |> Inflector.to_plural, [r1, r2]) |> sort
  Migration.new_relationship_table("create_relationship_table_$(names[1])_$(names[2])", names...)
end


function relationship_name(r1::Type{T}, r2::Type{R})::String where {T<:AbstractModel, R<:AbstractModel}
  map(x -> string(x) |> Inflector.to_plural, [r1, r2]) |> sort |> join
end


function relationship_field_name(x::Type{T})::String where {T<:AbstractModel}
  (string(x) |> lowercase |> Inflector.to_plural) * "_id"
end


function Relationship(r1::Type{T}, r2::Type{R}; context = @__MODULE__) where {T<:AbstractModel, R<:AbstractModel}
  Core.eval(context,
            Meta.parse("Base.@kwdef mutable struct $(relationship_name(r1, r2)) <: AbstractModel;
                          id::DbId = DbId();
                          $(relationship_field_name(r1))::DbId = DbId();
                          $(relationship_field_name(r2))::DbId = DbId();
                        end"))

  getfield(context, Symbol(relationship_name(r1, r2)))
end


function Relationship!(r1::T, r2::R; context::Module = @__MODULE__) where {T<:AbstractModel, R<:AbstractModel}
  relationship = (
                  isdefined(context, Symbol(relationship_name(typeof(r1), typeof(r2)))) ?
                  getfield(context, Symbol(relationship_name(typeof(r1), typeof(r2)))) :
                  Relationship(typeof(r1), typeof(r2); context = context)
                  )

  # invokelatest(relationship, DbId(), getfield(r1, Symbol(pk(r1))), getfield(r2, Symbol(pk(r2))))
  findone_or_create(relationship;
                    NamedTuple{ (Symbol(relationship_field_name(typeof(r1))), Symbol(relationship_field_name(typeof(r2)))) }(
                      (getfield(r1, pk(r1) |> Symbol), getfield(r2, pk(r2) |> Symbol)) )...) |> save!
end


end