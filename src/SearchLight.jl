module SearchLight

import Revise
import DataFrames, OrderedCollections, Distributed, Dates, Logging, Millboard, YAML

import DataFrames.DataFrame

include("constants.jl")

haskey(ENV, "SEARCHLIGHT_ENV") || (ENV["SEARCHLIGHT_ENV"] = "dev")

include("Exceptions.jl")

include("Configuration.jl")
using .Configuration

const config =  SearchLight.Configuration.Settings(app_env = ENV["SEARCHLIGHT_ENV"])

include("Inflector.jl")
include("model_types.jl")
include("Migration.jl")
include("Util.jl")
include("Validation.jl")
include("Generator.jl")

import .Util, .Validation
import .Inflector
import .Exceptions

export find, findone
export rand, randone
export all, count # min, max, mean, median
export findone_or_create, createwith, updateby_or_create, update_or_create
export save, save!, save!!, updatewith!, updatewith!!
export deleteall, delete
export validator

export ispersisted
export primary_key_name, table_name

include("serializers/JSONSerializer.jl")
using .JSONSerializer
const Serializer = JSONSerializer

#######################

function connect end


function disconnect end

#########################


# internals

mutable struct UnsupportedException <: Exception
  method_name::Symbol
  adapter_name::Symbol
end

Base.showerror(io::IO, e::UnsupportedException) = print(io, "Method $(e.method_name) is not supported by $(e.adapter_name)")


#
# ORM methods
#


function DataFrames.DataFrame(m::Type{T}, q::SQLQuery, j::Union{Nothing,Vector{SQLJoin{N}}} = nothing)::DataFrames.DataFrame where {T<:AbstractModel, N<:Union{AbstractModel,Nothing}}
  query(sql(m, q, j))::DataFrames.DataFrame
end

function DataFrames.DataFrame(m::Type{T}; order = SQLOrder(primary_key_name(m())))::DataFrames.DataFrame where {T<:AbstractModel}
  DataFrame(m, SQLQuery(order = order))
end

function DataFrames.DataFrame(m::Type{T}, w::SQLWhereEntity; order = SQLOrder(primary_key_name(m())))::DataFrames.DataFrame where {T<:AbstractModel}
  DataFrame(m, SQLQuery(where = [w], order = order))
end

function DataFrames.DataFrame(m::Type{T}, w::Vector{SQLWhereEntity}; order = SQLOrder(primary_key_name(m())))::DataFrames.DataFrame where {T<:AbstractModel}
  DataFrame(m, SQLQuery(where = w, order = order))
end

function DataFrames.DataFrame(args...)::DataFrames.DataFrame
  DataFrame(args...)
end


function find(m::Type{T}, q::SQLQuery, j::Union{Nothing,Vector{SQLJoin{N}}} = nothing)::Vector{T} where {T<:AbstractModel, N<:Union{Nothing,AbstractModel}}
  to_models(m, DataFrame(m, q, j))
end

function find(m::Type{T}, w::SQLWhereEntity;
                      order = SQLOrder(primary_key_name(m())))::Vector{T} where {T<:AbstractModel}
  find(m, SQLQuery(where = [w], order = order))
end

function find(m::Type{T}, w::Vector{SQLWhereEntity};
                      order = SQLOrder(primary_key_name(m())))::Vector{T} where {T<:AbstractModel}
  find(m, SQLQuery(where = w, order = order))
end

function find(m::Type{T};
                      order = SQLOrder(primary_key_name(m())),
                      limit = SQLLimit(),
                      where_conditions...)::Vector{T} where {T<:AbstractModel}
  find(m, SQLQuery(where = [SQLWhereExpression("$(SQLColumn(x)) = ?", y) for (x,y) in where_conditions], order = order, limit = limit))
end


function onereduce(collection::Vector{T})::Union{Nothing,T} where {T<:AbstractModel}
  isempty(collection) ? nothing : first(collection)
end


function findone(m::Type{T}; filters...)::Union{Nothing,T} where {T<:AbstractModel}
  find(m; filters...) |> onereduce
end


function randone(m::Type{T})::Union{Nothing,T} where {T<:AbstractModel}
  SearchLight.rand(m, limit = 1) |> onereduce
end


function Base.all(m::Type{T}; columns::Vector{SQLColumn} = SQLColumn[], order = SQLOrder(primary_key_name(m())), limit::Union{Int,SQLLimit,String} = SQLLimit("ALL"), offset::Int = 0)::Vector{T} where {T<:AbstractModel}
  find(m, SQLQuery(columns = columns, order = order, limit = limit, offset = offset))
end

function Base.all(m::Type{T}, query::SQLQuery)::Vector{T} where {T<:AbstractModel}
  find(m, query)
end


function Base.first(m::Type{T}; order = SQLOrder(primary_key_name(m())))::Union{Nothing,T} where {T<:AbstractModel}
  find(m, SQLQuery(order = order, limit = 1)) |> onereduce
end


function Base.last(m::Type{T}; order = SQLOrder(primary_key_name(m()), :desc))::Union{Nothing,T} where {T<:AbstractModel}
  find(m, SQLQuery(order = order, limit = 1)) |> onereduce
end


# TODO: max(), min(), avg(), mean(), etc


function save(m::T; conflict_strategy = :error, skip_validation = false, skip_callbacks = Vector{Symbol}())::Bool where {T<:AbstractModel}
  try
    _save!!(m, conflict_strategy = conflict_strategy, skip_validation = skip_validation, skip_callbacks = skip_callbacks)

    true
  catch ex
    @error ex

    false
  end
end


function save!(m::T; conflict_strategy = :error, skip_validation = false, skip_callbacks = Vector{Symbol}())::T where {T<:AbstractModel}
  save!!(m, conflict_strategy = conflict_strategy, skip_validation = skip_validation, skip_callbacks = skip_callbacks)
end
function save!!(m::T; conflict_strategy = :error, skip_validation = false, skip_callbacks = Vector{Symbol}())::T where {T<:AbstractModel}
  df::DataFrames.DataFrame = _save!!(m, conflict_strategy = conflict_strategy, skip_validation = skip_validation, skip_callbacks = skip_callbacks)

  id = if in(SearchLight.LAST_INSERT_ID_LABEL, names(df))
    df[1, SearchLight.LAST_INSERT_ID_LABEL]
  elseif in(Symbol(primary_key_name(m)), names(df))
    df[1, Symbol(primary_key_name(m))]
  end

  id === nothing && getfield(m, Symbol(primary_key_name(m))).value !== nothing &&
    (id = getfield(m, Symbol(primary_key_name(m))).value)

  id === nothing && throw(Exceptions.UnretrievedModelException(typeof(m), id))

  n = findone(typeof(m); (Symbol(primary_key_name(m))=>id, )...)

  n === nothing && throw(Exceptions.UnretrievedModelException(typeof(m), id))

  db_fields = persistable_fields(m)
  @sync Distributed.@distributed for f in fieldnames(typeof(m))
    in(string(f), db_fields) && setfield!(m, f, getfield(n, f))
  end

  m
end

function _save!!(m::T; conflict_strategy = :error, skip_validation = false, skip_callbacks = Vector{Symbol}())::DataFrames.DataFrame where {T<:AbstractModel}
  hasfield(m, :validator) && ! skip_validation &&
    ! Validation.validate!(m) &&
    throw(Exceptions.InvalidModelException(m, Validation.errors(m)))

  in(:before_save, skip_callbacks) || invoke_callback(m, :before_save)

  result = query(to_store_sql(m, conflict_strategy = conflict_strategy))

  in(:after_save, skip_callbacks) || invoke_callback(m, :after_save)

  result
end


function invoke_callback(m::T, callback::Symbol)::Tuple{Bool,T} where {T<:AbstractModel}
  if isdefined(m, callback)
    getfield(m, callback)(m)
    (true, m)
  else
    (false, m)
  end
end


function updatewith!(m::T, w::T)::T where {T<:AbstractModel}
  for fieldname in fieldnames(typeof(m))
    ( startswith(string(fieldname), "_") || string(fieldname) == primary_key_name(m) ) && continue
    setfield!(m, fieldname, getfield(w, fieldname))
  end

  m
end

function updatewith!(m::T, w::Dict)::T where {T<:AbstractModel}
  for fieldname in fieldnames(typeof(m))
    ( startswith(string(fieldname), "_") || string(fieldname) == primary_key_name(m) ) && continue

    value = if haskey(w, fieldname)
              w[fieldname]
            elseif haskey(w, string(fieldname))
              w[string(fieldname)]
            else
              nothing
            end

    value === nothing && continue

    value = if typeof(getfield(m, fieldname)) == Bool
              if lowercase(string(value)) == "on" || value == :on || value == "1" || value == 1 || lowercase(string(value)) == "true" || value == :true
                true
              elseif lowercase(string(value)) == "off" || value == :off || value == "0" || value == 0 || lowercase(string(value)) == "false" || value == :false || value == ""
                false
              end
            else
              try
                convert(typeof(getfield(m, fieldname)), value)
              catch ex
                if isdefined(m, :on_error!)
                  m = m.on_error!(ex, model = m, data = w, field = fieldname, value = value)::T
                  getfield(m, fieldname)
                else
                  rethrow(ex)
                end
              end
            end

    try
      setfield!(m, fieldname, convert(typeof(getfield(m, fieldname)), value))
    catch ex
      @error ex
      @error "obj = $(typeof(m)) -- field = $fieldname -- value = $value -- type = $(typeof(getfield(m, fieldname)))"

      rethrow(ex)
    end
  end

  m
end


function updatewith!!(m::T, w::Union{T,Dict})::T where {T<:AbstractModel}
  SearchLight.save!!(updatewith!(m, w))
end


function createwith(m::Type{T}, w::Dict)::T where {T<:AbstractModel}
  updatewith!(m(), w)
end


function updateby_or_create(m::T; ignore = Symbol[], skip_update = false, filters...)::T where {T<:AbstractModel}
  existing = findone(typeof(m), filters...)

  if existing !== nothing
    skip_update && return existing

    for fieldname in fieldnames(typeof(m))
      ( startswith(string(fieldname), "_") || string(fieldname) == primary_key_name(m) || in(fieldname, ignore) ) && continue
      setfield!(existing, fieldname, getfield(m, fieldname))
    end

    return SearchLight.save!!(existing)
  else
    m.id = DbId()
    return SearchLight.save!!(m)
  end
end


function update_or_create(m::T; ignore = Symbol[], skip_update = false)::T where {T<:AbstractModel}
  updateby_or_create(m; ignore = ignore, skip_update = skip_update, NamedTuple{ (Symbol(primary_key_name(m)),) }( (getfield(m, Symbol(primary_key_name(m))),) )...)
end


function findone_or_create(m::Type{T}; filters...)::T where {T<:AbstractModel}
  lookup = findone(m; filters...)
  lookup !== nothing && return lookup

  _m::T = m()
  for (property, value) in filters
    setfield!(_m, Symbol(is_fully_qualified(string(property)) ? from_fully_qualified(string(property))[end] : property), value)
  end

  _m
end


#
# Object generation
#


function to_models(m::Type{T}, df::DataFrames.DataFrame)::Vector{T} where {T<:AbstractModel}
  models = OrderedCollections.OrderedDict{DbId,T}()
  dfs = dataframes_by_table(m, df)

  row_count::Int = 1
  __m::T = m()
  for row in eachrow(df)
    main_model::T = to_model!!(m, dfs[table_name(__m)][row_count, :])

    if haskey(models, getfield(main_model, Symbol(primary_key_name(__m))).value)
      main_model = models[getfield(main_model, Symbol(primary_key_name(__m))).value]
    end

    if ! haskey(models, getfield(main_model, Symbol(primary_key_name(__m))).value) &&
          getfield(main_model, Symbol(primary_key_name(__m))).value !== nothing
      models[DbId(getfield(main_model, Symbol(primary_key_name(__m))).value)] = main_model
    end

    row_count += 1
  end

  models |> values |> collect
end


function to_model(m::Type{T}, row::DataFrames.DataFrameRow)::T where {T<:AbstractModel}
  _m::T = m()
  obj::T = m()
  sf = settable_fields(_m, row)
  set_fields = Symbol[]

  for field in sf
    unq_field = from_fully_qualified(_m, field)

    ismissing(row[field]) && continue # if it's NA we just leave the default value of the empty obj

    value = if isdefined(_m, :on_find!)
              try
                _m, value = _m.on_find!(_m, unq_field, row[field])
                value === nothing && (value = row[field])
                value
              catch ex
                @error "Failed to process on_find! the field $unq_field ($field)"
                @error ex

                row[field]
              end
            elseif isdefined(_m, :on_find)
              try
                value = _m.on_find(_m, unq_field, row[field])
                value === nothing && (value = row[field])
                value
              catch ex
                @error "Failed to process on_find the field $unq_field ($field)"
                @error ex

                row[field]
              end
            else
              row[field]
            end

    value = if in(:_serializable, fieldnames(typeof(_m))) && isa(_m._serializable, Vector{Symbol}) && in(unq_field, _m._serializable)
              Serializer.deserialize(value)
            else
              value
            end

    try
      setfield!(obj, unq_field, oftype(getfield(_m, unq_field), value))
    catch ex
      @error ex
      @error "obj = $(typeof(obj)) -- field = $unq_field -- value = $value -- type = $(typeof(getfield(_m, unq_field)))"

      isdefined(_m, :on_error!) ? obj = _m.on_error!(ex, model = obj, data = _m, field = unq_field, value = value)::T : rethrow(ex)
    end

    push!(set_fields, unq_field)
  end

  for field in fieldnames(typeof(_m))
    if ! in(field, set_fields)
      try
        setfield!(obj, field, getfield(_m, field))
      catch ex
        @error ex
        @error field
      end
    end
  end

  status = invoke_callback(obj, :after_find)
  status[1] && (obj = status[2])

  obj
end


function to_model!!(m::Type{T}, df::DataFrames.DataFrame; row_index = 1)::T where {T<:AbstractModel}
  dfr = DataFrames.DataFrameRow(df, row_index)

  to_model(m, dfr)
end

function to_model!!(m::Type{T}, dfr::DataFrames.DataFrameRow)::T where {T<:AbstractModel}
  to_model(m, dfr)
end


function to_model(m::Type{T}, df::DataFrames.DataFrame; row_index = 1)::Union{Nothing,T} where {T<:AbstractModel}
  size(df)[1] >= row_index ? to_model!!(m, df, row_index = row_index) : nothing
end


#
# Query generation
#


function to_select_part(m::Type{T}, cols::Vector{SearchLight.SQLColumn}, joins::Union{Nothing,Vector{SQLJoin{N}}} = nothing)::String where {T<:SearchLight.AbstractModel, N<:Union{Nothing,SearchLight.AbstractModel}}
  _m::T = m()

  sp = if ! isempty(cols)
    table_columns = []
    cols = vcat(cols, columns_from_joins(joins))

    for column in cols
      push!(table_columns, prepare_column_name(column, _m))
    end

    join(table_columns, ", ")
  else
    tbl_cols = join(SearchLight.to_fully_qualified_sql_column_names(_m, SearchLight.persistable_fields(_m), escape_columns = true), ", ")
    table_columns = isempty(tbl_cols) ? String[] : vcat(tbl_cols, map(x -> prepare_column_name(x, _m), columns_from_joins(joins)))

    join(table_columns, ", ")
  end

  string("SELECT ", sp)
end
function to_select_part(m::Type{T}, c::SQLColumn)::String where {T<:AbstractModel}
  to_select_part(m, [c])
end
function to_select_part(m::Type{T}, c::String)::String where {T<:AbstractModel}
  to_select_part(m, SQLColumn(c, raw = c == "*"))
end
function to_select_part(m::Type{T})::String where {T<:AbstractModel}
  to_select_part(m, SQLColumn[])
end


function to_from_part end


function to_where_part end


function to_order_part end


function to_group_part end


function to_limit_part end

function to_limit_part(l::Int)::String
  to_limit_part(SQLLimit(l))
end


function to_offset_part end


function to_having_part end


function to_join_part end


"""
  columns_from_joins(joins::Vector{SQLJoin})::Vector{SQLColumn}

Extracts columns from joins param and adds to be used for the SELECT part
"""
function columns_from_joins(joins::Union{Nothing,Vector{SQLJoin{N}}} = nothing)::Vector{SearchLight.SQLColumn} where {N<:Union{Nothing,SearchLight.AbstractModel}}
  jcols = SearchLight.SQLColumn[]

  joins === nothing && return jcols

  for j in joins
    jcols = vcat(jcols, j.columns)
  end

  jcols
end


function column_data_to_column_name end


function prepare_column_name(column::SearchLight.SQLColumn, _m::T)::String where {T<:SearchLight.AbstractModel}
  if column.raw
    column.value |> string
  else
    column_data::Dict{Symbol,Any} = SearchLight.from_literal_column_name(column.value)
    if ! haskey(column_data, :table_name)
      column_data[:table_name] = SearchLight.table_name(_m)
    end
    if ! haskey(column_data, :alias)
      column_data[:alias] = ""
    end

    column_data_to_column_name(column, column_data)
  end
end


function columns_names_by_table(tables_names::Vector{String}, df::DataFrames.DataFrame)::Dict{String,Vector{Symbol}}
  tables_columns = Dict{String,Vector{Symbol}}()

  for t in tables_names
    tables_columns[t] = Symbol[]
  end

  for dfc in names(df)
    table_name = ""
    sdfc = string(dfc)

    ! occursin("_", sdfc) && continue

    for t in tables_names
      if startswith(sdfc, t)
        table_name = t
        break
      end
    end

    ! in(table_name, tables_names) && continue

    push!(tables_columns[table_name], dfc)
  end

  tables_columns
end


function dataframes_by_table(tables_names::Vector{String}, tables_columns::Dict{String,Vector{Symbol}}, df::DataFrames.DataFrame)::Dict{String,DataFrames.DataFrame}
  sub_dfs = Dict{String,DataFrames.DataFrame}()

  for t in tables_names
    sub_dfs[t] = df[:, tables_columns[t]]
  end

  sub_dfs
end
function dataframes_by_table(m::Type{T}, df::DataFrames.DataFrame)::Dict{String,DataFrames.DataFrame} where {T<:AbstractModel}
  tables_names = String[table_name(m())]

  dataframes_by_table(tables_names, columns_names_by_table(tables_names, df), df)
end


function to_find_sql end
const to_fetch_sql = to_find_sql


function to_store_sql end


function to_sqlinput(m::T, field::Symbol, value)::SQLInput where {T<:AbstractModel}
  value = if isdefined(m, :on_save)
            try
              r = m.on_save(m, field, value)
              r === nothing ? value : r
            catch ex
              @error "Failed to persist field $field"
              @error ex

              value
            end
          else
            value
          end

  value = if in(:_serializable, fieldnames(typeof(m))) && isa(m._serializable, Vector{Symbol}) && in(field, m._serializable)
            Serializer.serialize(value)
          else
            value
          end

  SQLInput(value)
end


#
# delete methods
#


function delete_all end;
const deleteall = delete_all


function delete end

#
# query execution
#


function query end


#
# ORM utils
#


function clone(o::T, fieldname::Symbol, value::Any)::T where {T<:SQLType}
  content = Dict{Symbol,Any}()
  for field in fieldnames(typeof(o))
    content[field] = getfield(o, field)
  end
  content[fieldname] = value

  T(; content...)
end


function clone(o::T, changes::Dict{Symbol,Any})::T where {T<:SQLType}
  content = Dict{Symbol,Any}()
  for field in fieldnames(typeof(o))
    content[field] = getfield(o, field)
  end
  content = merge(content, changes)

  T(; content...)
end


function columns end


function ispersisted(m::T)::Bool where {T<:AbstractModel}
  getfield(m, Symbol(primary_key_name(m))).value !== nothing
end


function column_field_name end


function persistable_fields(m::T; fully_qualified::Bool = false)::Vector{String} where {T<:AbstractModel}
  object_fields = map(x -> string(x), fieldnames(typeof(m)))
  db_columns =  try
                  columns(typeof(m))[!, column_field_name()]
                catch ex
                  @error ex
                  []
                end

  pst_fields = intersect(object_fields, db_columns)

  fully_qualified ? to_fully_qualified_sql_column_names(m, pst_fields) : pst_fields
end


function settable_fields(m::T, row::DataFrames.DataFrameRow)::Vector{Symbol} where {T<:AbstractModel}
  df_cols::Vector{Symbol} = names(row)
  fields = is_fully_qualified(m, df_cols[1]) ? to_sql_column_names(m, fieldnames(typeof(m))) : fieldnames(typeof(m))

  intersect(fields, df_cols)
end


#
# utility functions
#


function table_name(m::T)::String where {T<:AbstractModel}
  if in(:_table_name, fieldnames(typeof(m)))
    m._table_name
  else
    Inflector.to_plural(string(typeof(m))) |> get |> lowercase
  end
end
function table_name(m::Type{T})::String where {T<:AbstractModel}
  table_name(m())
end


function primary_key_name(m::T)::String where {T<:AbstractModel}
  m._id
end

function primary_key_name(m::Type{T})::String where {T<:AbstractModel}
  primary_key_name(m())
end

const id = primary_key_name


function validator(m::T)::Union{Nothing,SearchLight.Validation.ModelValidator} where {T<:AbstractModel}
  Validation.validator!!(m)
end


function hasfield(m::T, f::Symbol)::Bool where {T<:AbstractModel}
  isdefined(m, f)
end


function strip_table_name(m::T, f::Symbol)::Symbol where {T<:AbstractModel}
  replace(string(f), Regex("^$(table_name(m))_") => "", count = 1) |> Symbol
end


function is_fully_qualified(m::T, f::Symbol)::Bool where {T<:AbstractModel}
  startswith(string(f), table_name(m)) && hasfield(m, strip_table_name(m, f))
end
function is_fully_qualified(t::T)::Bool where {T<:SQLType}
  replace(t |> string, "\""=>"") |> string |> is_fully_qualified
end


function is_fully_qualified(s::String)::Bool
  ! startswith(s, ".") && occursin(".", s)
end


function from_fully_qualified(m::T, f::Symbol)::Symbol where {T<:AbstractModel}
  is_fully_qualified(m, f) ? strip_table_name(m, f) : f
end


function from_fully_qualified(s::String)::Tuple{String,String}
  ! occursin(".", s) && throw("$s is not a fully qualified SQL column name in the format table_name.column_name")

  (x,y) = split(s, ".")

  (string(x),string(y))
end
function from_fully_qualified(t::T)::Tuple{String,String} where {T<:SQLType}
  replace(t |> string, "\""=>"") |> string |> from_fully_qualified
end


function strip_module_name(s::String)::String
  split(s, ".") |> last
end


function to_fully_qualified(v::String, t::String)::String
  t * "." * v
end


function to_fully_qualified(m::T, v::String)::String where {T<:AbstractModel}
  to_fully_qualified(v, table_name(m))
end
function to_fully_qualified(m::T, c::SQLColumn)::String where {T<:AbstractModel}
  c.raw && return c.value
  to_fully_qualified(c.value, table_name(m))
end
function to_fully_qualified(m::Type{T}, c::SQLColumn)::String where {T<:AbstractModel}
  to_fully_qualified(m(), c)
end


function to_sql_column_names(m::T, fields::Vector{Symbol})::Vector{Symbol} where {T<:AbstractModel}
  map(x -> (to_sql_column_name(m, string(x))) |> Symbol, fields)
end
function to_sql_column_names(m::T, fields::Tuple)::Vector{Symbol} where {T<:AbstractModel}
  to_sql_column_names(m, Symbol[fields...])
end


function to_sql_column_name(v::String, t::String)::String
  str = Util.strip_quotes(t) * "_" * Util.strip_quotes(v)
  if Util.is_quoted(t) && Util.is_quoted(v)
    Util.add_quotes(str)
  else
    str
  end
end
function to_sql_column_name(m::T, v::String)::String where {T<:AbstractModel}
  to_sql_column_name(v, table_name(m))
end
function to_sql_column_name(m::T, c::SQLColumn)::String where {T<:AbstractModel}
  to_sql_column_name(c.value, table_name(m))
end


function to_fully_qualified_sql_column_names(m::T, persistable_fields::Vector{String}; escape_columns::Bool = false)::Vector{String} where {T<:AbstractModel}
  map(x -> to_fully_qualified_sql_column_name(m, x, escape_columns = escape_columns), persistable_fields)
end


function to_fully_qualified_sql_column_name(m::T, f::String; escape_columns::Bool = false, alias::String = "")::String where {T<:AbstractModel}
  if escape_columns
    "$(to_fully_qualified(m, f) |> escape_column_name) AS $(isempty(alias) ? (to_sql_column_name(m, f) |> escape_column_name) : alias)"
  else
    "$(to_fully_qualified(m, f)) AS $(isempty(alias) ? to_sql_column_name(m, f) : alias)"
  end
end


function from_literal_column_name(c::String)::Dict{Symbol,String}
  result = Dict{Symbol,String}()
  result[:original_string] = c

  # has alias?
  if occursin(" AS ", c)
    parts = split(c, " AS ")
    result[:column_name] = parts[1]
    result[:alias] = parts[2]
  else
    result[:column_name] = c
  end

  # is fully qualified?
  if occursin(".", result[:column_name])
    parts = split(result[:column_name], ".")
    result[:table_name] = parts[1]
    result[:column_name] = parts[2]
  end

  result
end


function to_dict(m::T; all_fields::Bool = false)::Dict{String,Any} where {T<:AbstractModel}
  Dict( string(f) => Util.expand_nullable( getfield(m, Symbol(f)) ) for f in (all_fields ? fieldnames(typeof(m)) : persistable_fields(m)) )
end


function to_dict(m::Any)::Dict{String,Any}
  Dict(string(f) => getfield(m, Symbol(f)) for f in fieldnames(typeof(m)))
end


function to_string_dict(m::T; all_fields::Bool = false, all_output::Bool = false)::Dict{String,String} where {T<:AbstractModel}
  fields = all_fields ? fieldnames(typeof(m)) : persistable_fields(m)
  response = Dict{String,String}()

  for f in fields
    value = getfield(m, Symbol(f))
    response[string(f) * "::" * string(typeof(value))] = string(value)
  end

  response
end
function to_string_dict(m::Any; all_output::Bool = false)::Dict{String,String}
  to_string_dict(m, [f for f in fieldnames(typeof(m))], all_output = all_output)
end
function to_string_dict(m::Any, fields::Vector{Symbol}; all_output::Bool = false)::Dict{String,String}
  response = Dict{String,String}()
  for f in fields
    response[string(f)] = string(string(getfield(m, Symbol(f))))
  end

  response
end


function dataframe_to_dict(df::DataFrames.DataFrame)::Vector{Dict{Symbol,Any}}
  result = Dict{Symbol,Any}[]
  for r in eachrow(df)
    push!(result, Dict{Symbol,Any}( [k => r[k] for k in DataFrames.names(df)] ) )
  end

  result
end


function enclosure(v::Any, o::Any)::String
  in(string(o), ["IN", "in"]) ? "($(string(v)))" : string(v)
end


function update_query_part end


function escape_column_name end


function escape_value end


function index_name(table_name::Union{String,Symbol}, column_name::Union{String,Symbol}) :: String
  string(table_name) * "__" * "idx_" * string(column_name)
end


function sql(m::Type{T}, q::SQLQuery = SQLQuery(), j::Union{Nothing,Vector{SQLJoin{N}}} = nothing)::String where {T<:AbstractModel, N<:Union{Nothing,AbstractModel}}
  to_fetch_sql(m, q, j)
end

function sql(m::T)::String where {T<:AbstractModel}
  to_store_sql(m)
end


include("QueryBuilder.jl")

end