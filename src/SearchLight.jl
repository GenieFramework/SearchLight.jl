module SearchLight

import DataFrames, OrderedCollections, Distributed, Dates, Logging, Millboard, YAML
import DataFrames.DataFrame

include("constants.jl")

haskey(ENV, "SEARCHLIGHT_ENV") || (ENV["SEARCHLIGHT_ENV"] = "dev")

include("Exceptions.jl")
using .Exceptions

import Inflector

include("Configuration.jl")
using .Configuration

const config =  SearchLight.Configuration.Settings(app_env = ENV["SEARCHLIGHT_ENV"])

include("model_types.jl")
include("Migration.jl")
include("Validation.jl")
include("Serializer.jl")
include("Generator.jl")
include("Relationships.jl")
include("Transactions.jl")
include("Callbacks.jl")

export find, findone
export rand, randone
export all, count # min, max, mean, median
export findone_or_create, createwith, updateby_or_create, update_or_create
export save, save!, save!!, updatewith!, updatewith!!
export deleteall, delete

export ispersisted
export pk, table

#######################

function connect end


function disconnect end


function connection end

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


function DataFrames.DataFrame(m::Type{T}, q::SQLQuery, j::Union{Nothing,Vector{SQLJoin}} = nothing)::DataFrames.DataFrame where {T<:AbstractModel}
  query(sql(m, q, j))::DataFrames.DataFrame
end

function DataFrames.DataFrame(m::Type{T}; order = SQLOrder(pk(m)))::DataFrames.DataFrame where {T<:AbstractModel}
  DataFrame(m, SQLQuery(order = order))
end

function DataFrames.DataFrame(m::Type{T}, w::SQLWhereEntity; order = SQLOrder(pk(m)))::DataFrames.DataFrame where {T<:AbstractModel}
  DataFrame(m, SQLQuery(where = [w], order = order))
end

function DataFrames.DataFrame(m::Type{T}, w::Vector{SQLWhereEntity}; order = SQLOrder(pk(m)))::DataFrames.DataFrame where {T<:AbstractModel}
  DataFrame(m, SQLQuery(where = w, order = order))
end

"""
    find(m::Type{T}, q::SQLQuery, j::Union{Nothing,Vector{SQLJoin}} = nothing)::Vector{T} where {T<:AbstractModel}

# Examples
```julia

```
"""
function find(m::Type{T}, q::SQLQuery, j::Union{Nothing,Vector{SQLJoin}} = nothing)::Vector{T} where {T<:AbstractModel}
  @show "doing it"
  to_models(m, DataFrame(m, q, j))
end

"""
    find(m::Type{T}, w::SQLWhereEntity; order = SQLOrder(pk(m)))::Vector{T} where {T<:AbstractModel}

Return a vector of `AbstractModel` given Model instance where `query` and `order` by 
  
# Examples
```julia
julia> using Dates, Stats

julia> startdate = Dates.Date("2021-11-25")
2021-11-25

julia> enddate = Dates.Date("2021-11-25")
2021-11-25

julia> find(Stat, SQLWhereExpression("date >= ? AND date <= ?", startdate, enddate), order=["stats.date"])
8160-element Vector{Stat}:
 Stat
| KEY                  | VALUE                                |
|----------------------|--------------------------------------|
| date::Date           | 2021-11-25                           |
| id::DbId             | 1                                    |
| month::String        | 2021-11                              |
| package_name::String | REPLTreeViews                        |
| package_uuid::String | 00000000-1111-2222-3333-444444444444 |
| region::String       | cn-northeast                         |
| request_count::Int64 | 1                                    |
| status::Int64        | 200                                  |
| year::Int64          | 2021                                 |
  
  ⋮
Stat
| KEY                  | VALUE                                |
|----------------------|--------------------------------------|
| date::Date           | 2021-11-25                           |
| id::DbId             | 623498                               |
| month::String        | 2021-11                              |
| package_name::String | SimpleANOVA                          |
| package_uuid::String | fff527a3-8410-504e-9ca3-60d5e79bb1e4 |
| region::String       | eu-central                           |
| request_count::Int64 | 1                                    |
| status::Int64        | 200                                  |
| year::Int64          | 2021                                 |
```
"""
function find(m::Type{T}, w::SQLWhereEntity;
                      order = SQLOrder(pk(m)))::Vector{T} where {T<:AbstractModel}
  @show "2nd find"
  find(m, SQLQuery(where = [w], order = order))
end


function find(m::Type{T}, w::Vector{SQLWhereEntity};
                      order = SQLOrder(pk(m)))::Vector{T} where {T<:AbstractModel}
  @show "3rd find"
  find(m, SQLQuery(where = w, order = order))
end

function find(m::Type{T};
                      order = SQLOrder(pk(m)),
                      limit = SQLLimit(),
                      where_conditions...)::Vector{T} where {T<:AbstractModel}
  @show "4th find"
  find(m, SQLQuery(where = [SQLWhereExpression("$(SQLColumn(x)) = ?", y) for (x,y) in where_conditions], order = order, limit = limit))
end


function onereduce(collection::Vector{T})::Union{Nothing,T} where {T<:AbstractModel}
  isempty(collection) ? nothing : first(collection)
end


function findone(m::Type{T}; filters...)::Union{Nothing,T} where {T<:AbstractModel}
  find(m; filters...) |> onereduce
end

function Base.one(m::Type{T}; filters...)::Union{Nothing,T} where {T<:AbstractModel}
  findone(m; filters...)
end


function randone(m::Type{T})::Union{Nothing,T} where {T<:AbstractModel}
  SearchLight.rand(m, limit = 1) |> onereduce
end


function Base.all(m::Type{T}; columns::Vector{SQLColumn} = SQLColumn[], order = SQLOrder(pk(m)), limit::Union{Int,SQLLimit,String} = SQLLimit("ALL"), offset::Int = 0)::Vector{T} where {T<:AbstractModel}
  find(m, SQLQuery(columns = columns, order = order, limit = limit, offset = offset))
end

function Base.all(m::Type{T}, query::SQLQuery)::Vector{T} where {T<:AbstractModel}
  find(m, query)
end


function Base.first(m::Type{T}; order = SQLOrder(pk(m)))::Union{Nothing,T} where {T<:AbstractModel}
  find(m, SQLQuery(order = order, limit = 1)) |> onereduce
end


function Base.last(m::Type{T}; order = SQLOrder(pk(m), :desc))::Union{Nothing,T} where {T<:AbstractModel}
  find(m, SQLQuery(order = order, limit = 1)) |> onereduce
end


# TODO: max(), min(), avg(), mean(), etc


function save(m::T; conflict_strategy::Symbol = :error, skip_validation::Bool = false, skip_callbacks::Vector{Symbol} = Symbol[])::Bool where {T<:AbstractModel}
  try
    _save!!(m, conflict_strategy = conflict_strategy, skip_validation = skip_validation, skip_callbacks = skip_callbacks)

    true
  catch ex
    @error ex

    false
  end
end


function save!(m::T; conflict_strategy::Symbol = :error, skip_validation::Bool = false, skip_callbacks::Vector{Symbol} = Symbol[])::T where {T<:AbstractModel}
  save!!(m, conflict_strategy = conflict_strategy, skip_validation = skip_validation, skip_callbacks = skip_callbacks)
end
function save!!(m::T; conflict_strategy::Symbol = :error, skip_validation::Bool = false, skip_callbacks::Vector{Symbol} = Symbol[])::T where {T<:AbstractModel}
  df::DataFrames.DataFrame = _save!!(m, conflict_strategy = conflict_strategy, skip_validation = skip_validation, skip_callbacks = skip_callbacks)

  id = if in(SearchLight.LAST_INSERT_ID_LABEL, names(df))
    df[1, SearchLight.LAST_INSERT_ID_LABEL]
  elseif in(Symbol(pk(m)), names(df))
    df[1, Symbol(pk(m))]
  elseif in(String(pk(m)), names(df))
    df[1, String(pk(m))]
  end

  id === nothing && getfield(m, Symbol(pk(m))).value !== nothing &&
    (id = getfield(m, Symbol(pk(m))).value)

  id === nothing && throw(SearchLight.Exceptions.UnretrievedModelException(typeof(m), id))

  n = findone(typeof(m); (Symbol(pk(m))=>id, )...)

  n === nothing && throw(SearchLight.Exceptions.UnretrievedModelException(typeof(m), id))

  db_fields = persistable_fields(typeof(m))
  @sync Distributed.@distributed for f in fieldnames(typeof(m))
    in(string(f), db_fields) && setfield!(m, f, getfield(n, f))
  end

  m
end

function _save!!(m::T; conflict_strategy::Symbol = :error, skip_validation::Bool = false, skip_callbacks::Vector{Symbol} = Symbol[])::DataFrames.DataFrame where {T<:AbstractModel}
  if ! skip_validation
    model_validator = Validation.validate(m)
    Validation.haserrors(model_validator) &&
      throw(SearchLight.Exceptions.InvalidModelException(m, model_validator.errors, "Model $(typeof(m)) is not valid: $(Validation.errors_to_string(model_validator))"))
  end

  ! in(:before_save, skip_callbacks) && hasmethod(Callbacks.before_save, Tuple{typeof(m)}) &&  Callbacks.before_save(m)

  result = query(to_store_sql(m, conflict_strategy = conflict_strategy))

  ! in(:after_save, skip_callbacks) && hasmethod(Callbacks.after_save, Tuple{typeof(m)}) && Callbacks.after_save(m)

  result
end


function updatewith!(m::T, w::T)::T where {T<:AbstractModel}
  for fieldname in fieldnames(typeof(m))
    string(fieldname) == pk(m) && continue
    setfield!(m, fieldname, getfield(w, fieldname))
  end

  m
end

function updatewith!(m::T, w::Dict; skip_callbacks::Vector{Symbol} = Symbol[])::T where {T<:AbstractModel}
  for fieldname in fieldnames(typeof(m))
    string(fieldname) == pk(m) && continue

    value = if haskey(w, fieldname)
              w[fieldname]
            elseif haskey(w, string(fieldname))
              w[string(fieldname)]
            else
              continue
            end

    value = if typeof(getfield(m, fieldname)) == Bool
              booltypes(value)
            else
              try
                autoconvert(convertmethod(m, fieldname, value), m, fieldname, value)
              catch ex
                if ! in(:on_exception, skip_callbacks) && hasmethod(Callbacks.on_exception, Tuple{typeof(m),TypeConversionException})
                  m::T = Callbacks.on_exception(m, TypeConversionException(m, fieldname, value, ex))::T
                  getfield(m, fieldname)
                else
                  rethrow(ex)
                end
              end
            end

    try
      setfield!(m, fieldname, autoconvert(convertmethod(m, fieldname, value), m, fieldname, value))
    catch ex
      if ! in(:on_exception, skip_callbacks) && hasmethod(Callbacks.on_exception, Tuple{typeof(m),TypeConversionException})
        m = Callbacks.on_exception(m, TypeConversionException(fieldname, value, ex))::T
        setfield!(m, fieldname, parse(typeof(getfield(m, fieldname)), value))
      else
        rethrow(ex)
      end
    end
  end

  m
end


function convertmethod(m::T, fieldname::Symbol, value::Any) where {T<:AbstractModel}
  # @show fieldname, typeof(getfield(m, fieldname)), typeof(value)
  if typeof(getfield(m, fieldname)) == typeof(value)
    identity
  elseif hasmethod(parse, Tuple{Type{typeof(getfield(m, fieldname))},typeof(value)})
    parse
  elseif hasmethod(convert, Tuple{Type{typeof(getfield(m, fieldname))},typeof(value)})
    convert
  elseif hasmethod(typeof(getfield(m, fieldname)), Tuple{typeof(value)})
    typeof(getfield(m, fieldname)) # constructor
  else
    MissingConversionMethodException
  end
end


function booltypes(value::Any) :: Bool
  if lowercase(string(value)) == "on" || value == :on || value == "1" || value == 1 || lowercase(string(value)) == "true" || value == :true
    true
  elseif lowercase(string(value)) == "off" || value == :off || value == "0" || value == 0 || lowercase(string(value)) == "false" || value == :false || value == ""
    false
  end
end


function autoconvert(mthd, m::T, fieldname::Symbol, value::Any) where {T<:AbstractModel, R}
  if Symbol(mthd) in [:convert, :parse]
    mthd(typeof(getfield(m, fieldname)), value)
  elseif occursin("MissingConversionMethodException", string(mthd))
    mthd(typeof(getfield(m, fieldname)), value) |> throw
  else
    mthd(value) # constructor
  end
end


function updatewith!!(m::T, w::Union{T,Dict})::T where {T<:AbstractModel}
  SearchLight.save!!(updatewith!(m, w))
end


const updatewith = updatewith!


function createwith(m::Type{T}, w::Dict)::T where {T<:AbstractModel}
  updatewith!(m(), w)
end


function updateby_or_create(m::T; ignore = Symbol[], skip_update = false, filters...)::T where {T<:AbstractModel}
  existing = findone(typeof(m); filters...)

  if existing !== nothing
    skip_update && return existing

    for fieldname in fieldnames(typeof(m))
      ( string(fieldname) == pk(m) || in(fieldname, ignore) ) && continue
      setfield!(existing, fieldname, getfield(m, fieldname))
    end

    return SearchLight.save!!(existing)
  else
    m.id = DbId()
    return SearchLight.save!!(m)
  end
end

"""
    update_or_create(m::T; ignore = Symbol[], skip_update = false, filters...)::T where {T<:AbstractModel}


# Examples
```julia
julia> 
```
"""
function update_or_create(m::T; ignore = Symbol[], skip_update = false, filters...)::T where {T<:AbstractModel}
  isempty(filters) && (filters = NamedTuple{ (Symbol(pk(m)),) }( (getfield(m, Symbol(pk(m))),) ))
  updateby_or_create(m; ignore = ignore, skip_update = skip_update, filters...)
end


function findone_or_create(m::Type{T}; filters...)::T where {T<:AbstractModel}
  lookup = findone(m; filters...)
  lookup !== nothing && return lookup

  _m::T = try
    m()
  catch ex
    isa(ex, MethodError) ? Base.invokelatest(m) : rethrow(ex)
  end

  for (property, value) in filters
    setfield!(_m, Symbol(is_fully_qualified(string(property)) ? from_fully_qualified(string(property))[end] : property), value)
  end

  _m
end


#
# Object generation
#

"""
    to_models(m::Type{T}, df::DataFrames.DataFrame)::Vector{T} where {T<:AbstractModel}

Return an array of type `Model`

# Examples
```julia
julia> DataFrame(Stat, SQLWhereExpression("date >= ? AND date <= ?", startdate, enddate), order=["stats.date"])
8160×9 DataFrame
  Row │ stats_id  stats_package_uuid                 stats_package_name   stats_status  stats_region  stats_date  stats_request_count  stats_year  stats_month
      │ Int64     String                             String               Int64         String        String      Int64                Int64       String
──────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    1 │        1  00000000-1111-2222-3333-44444444…  REPLTreeViews                 200  cn-northeast  2021-11-25                    1        2021  2021-11
    2 │       17  00701ae9-d1dc-5365-b64a-a3a3ebf5…  BioAlignments                 200  au            2021-11-25                    1        2021  2021-11
    3 │      217  00701ae9-d1dc-5365-b64a-a3a3ebf5…  BioAlignments                 200  us-west       2021-11-25                    1        2021  2021-11
    4 │      314  009559a3-9522-5dbb-924b-0b6ed2b2…  XGBoost                       200  cn-northeast  2021-11-25                    1        2021  2021-11
    5 │      406  009559a3-9522-5dbb-924b-0b6ed2b2…  XGBoost                       200  eu-central    2021-11-25                    5        2021  2021-11
    6 │      461  009559a3-9522-5dbb-924b-0b6ed2b2…  XGBoost                       200  sa            2021-11-25                    1        2021  2021-11
    ⋮
 8160 │   623498  fff527a3-8410-504e-9ca3-60d5e79b…  SimpleANOVA                   200  eu-central    2021-11-25                    1        2021  2021-11

julia> SearchLight.to_models(Stat, DataFrame(Stat, SQLWhereExpression("date >= ? AND date <= ?", startdate, enddate), order=["stats.date"]))
8160-element Vector{Stat}:
 Stat
| KEY                  | VALUE                                |
|----------------------|--------------------------------------|
| date::Date           | 2021-11-25                           |
| id::DbId             | 1                                    |
| month::String        | 2021-11                              |
| package_name::String | REPLTreeViews                        |
| package_uuid::String | 00000000-1111-2222-3333-444444444444 |
| region::String       | cn-northeast                         |
| request_count::Int64 | 1                                    |
| status::Int64        | 200                                  |
| year::Int64          | 2021                                 |
 ⋮
 Stat
| KEY                  | VALUE                                |
|----------------------|--------------------------------------|
| date::Date           | 2021-11-25                           |
| id::DbId             | 623498                               |
| month::String        | 2021-11                              |
| package_name::String | SimpleANOVA                          |
| package_uuid::String | fff527a3-8410-504e-9ca3-60d5e79bb1e4 |
| region::String       | eu-central                           |
| request_count::Int64 | 1                                    |
| status::Int64        | 200                                  |
| year::Int64          | 2021                                 |
```
"""
function to_models(m::Type{T}, df::DataFrames.DataFrame)::Vector{T} where {T<:AbstractModel}
  models = OrderedCollections.OrderedDict{DbId,T}()
  dfs = dataframes_by_table(m, df)

  row_count::Int = 1
  for row in eachrow(df)
    main_model::T = to_model!!(m, dfs[table(m)][row_count, :])

    if haskey(models, getfield(main_model, Symbol(pk(m))).value)
      main_model = models[getfield(main_model, Symbol(pk(m))).value]
    end

    if ! haskey(models, getfield(main_model, Symbol(pk(m))).value) &&
          getfield(main_model, Symbol(pk(m))).value !== nothing
      models[DbId(getfield(main_model, Symbol(pk(m))).value)] = main_model
    end

    row_count += 1
  end

  models |> values |> collect
end


function to_model(m::Type{T}, row::DataFrames.DataFrameRow; skip_callbacks::Vector{Symbol} = Symbol[])::T where {T<:AbstractModel}
  _m::T = try
    m()
  catch ex
    isa(ex, MethodError) ? Base.invokelatest(m) : rethrow(ex)
  end

  obj::T = try
    m()
  catch ex
    isa(ex, MethodError) ? Base.invokelatest(m) : rethrow(ex)
  end

  set_fields = Symbol[]

  for field in settable_fields(m, row)
    unq_field = from_fully_qualified(m, field)

    ismissing(row[field]) && continue # if it's NA we just leave the default value of the empty obj

    value = if ! in(:on_find, skip_callbacks) && hasmethod(Callbacks.on_find, Tuple{typeof(_m),Symbol,typeof(row[field])})
              try
                _m = Callbacks.on_find(_m, unq_field, row[field])

                getfield(_m, unq_field)
              catch ex
                @error ex

                row[field]
              end
            else
              row[field]
            end

      value = if isdefined(Serializer, :serializables) &&
                  hasmethod(Serializer.serializables, Tuple{typeof(m)}) &&
                  in(unq_field, Serializer.serializables(m))
                Serializer.deserialize(typeof(getfield(_m, unq_field)), value)
              else
                value
              end

    try
      setfield!(obj, unq_field, oftype(getfield(_m, unq_field), value))
    catch ex
      @error ex

      ! in(:on_exception, skip_callbacks) && hasmethod(Callbacks.on_exception, Tuple{typeof(_m),TypeConversionException}) ?
        (obj = Callbacks.on_exception(obj, TypeConversionException(obj, unq_field, value, ex))::T) :
        rethrow(ex)
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

  if ! in(:after_find, skip_callbacks) && hasmethod(Callbacks.after_find, Tuple{typeof(obj)})
    obj = Callbacks.after_find(obj)
  end

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


function to_select_part(m::Type{T}, cols::Vector{SearchLight.SQLColumn}, joins::Union{Nothing,Vector{SQLJoin}} = nothing)::String where {T<:SearchLight.AbstractModel}
  sp = if ! isempty(cols)
    table_columns = []
    cols = vcat(cols, columns_from_joins(joins))

    for column in cols
      push!(table_columns, prepare_column_name(column, m))
    end

    join(table_columns, ", ")
  else
    tbl_cols = join(SearchLight.to_fully_qualified_sql_column_names(m, SearchLight.persistable_fields(m), escape_columns = true), ", ")
    table_columns = isempty(tbl_cols) ? String[] : vcat(tbl_cols, map(x -> prepare_column_name(x, m), columns_from_joins(joins)))

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
function columns_from_joins(joins::Union{Nothing,Vector{SQLJoin}} = nothing)::Vector{SearchLight.SQLColumn}
  jcols = SearchLight.SQLColumn[]

  joins === nothing && return jcols

  for j in joins
    jcols = vcat(jcols, j.columns)
  end

  jcols
end


function column_data_to_column_name end


function prepare_column_name(column::SearchLight.SQLColumn, m::Type{T})::String where {T<:SearchLight.AbstractModel}
  if column.raw
    column.value |> string
  else
    column_data::Dict{Symbol,Any} = SearchLight.from_literal_column_name(column.value)
    if ! haskey(column_data, :table_name)
      column_data[:table_name] = SearchLight.table(m)
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

    push!(tables_columns[table_name], dfc |> Symbol)
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
  tables_names = String[table(m)]

  dataframes_by_table(tables_names, columns_names_by_table(tables_names, df), df)
end


function to_find_sql end
const to_fetch_sql = to_find_sql


function to_store_sql end


function to_sqlinput(m::T, field::Symbol, value; skip_callbacks::Vector{Symbol} = Symbol[])::SQLInput where {T<:AbstractModel}
  value = if ! in(:on_save, skip_callbacks) && hasmethod(Callbacks.on_save, Tuple{typeof(m),Symbol,typeof(value)})
            try
              m = Callbacks.on_save(m, field, value)

              getfield(m, field)
            catch ex
              @error ex

              value
            end
          else
            value
          end

  value = if hasmethod(Serializer.serializables, Tuple{typeof(m)}) &&
              in(field, Serializer.serializables(typeof(m))) &&
              hasmethod(Serializer.serialize, Tuple{typeof(value)})
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
  getfield(m, Symbol(pk(m))).value !== nothing
end


function column_field_name end


function persistable_fields(m::Type{T}; fully_qualified::Bool = false)::Vector{String} where {T<:AbstractModel}
  object_fields = [map(x -> string(x), fieldnames(m))...]
  fully_qualified ? to_fully_qualified_sql_column_names(m, object_fields) : object_fields
end


function settable_fields(m::Type{T}, row::DataFrames.DataFrameRow)::Vector{Symbol} where {T<:AbstractModel}
  df_cols::Vector{Symbol} = map(x -> Symbol(x), names(row))
  fields = is_fully_qualified(m, df_cols[1]) ? to_sql_column_names(m, fieldnames(m)) : fieldnames(m)

  intersect(fields, df_cols)
end


#
# utility functions
#


function table(m::Type{T})::String where {T<:AbstractModel}
  Inflector.to_plural(string(m) |> strip_module_name) |> lowercase
end


function pk(m::T)::String where {T<:AbstractModel}
  pk(typeof(m))
end


function pk(m::Type{T})::String where {T<:AbstractModel}
  "id"
end

const primary_key_name = pk


function strip_table_name(m::Type{T}, f::Symbol)::Symbol where {T<:AbstractModel}
  replace(string(f), Regex("^$(table(m))_") => "", count = 1) |> Symbol
end


function is_fully_qualified(m::Type{T}, f::Symbol)::Bool where {T<:AbstractModel}
  startswith(string(f), table(m)) && hasfield(m, strip_table_name(m, f))
end
function is_fully_qualified(t::Type{T})::Bool where {T<:SQLType}
  replace(t |> string, "\""=>"") |> string |> is_fully_qualified
end


function is_fully_qualified(s::String)::Bool
  ! startswith(s, ".") && occursin(".", s)
end


function from_fully_qualified(m::Type{T}, f::Symbol)::Symbol where {T<:AbstractModel}
  is_fully_qualified(m, f) ? strip_table_name(m, f) : f
end


function from_fully_qualified(s::String)::Tuple{String,String}
  ! occursin(".", s) && throw("$s is not a fully qualified SQL column name in the format table_name.column_name")

  (x,y) = split(s, ".")

  (string(x),string(y))
end
function from_fully_qualified(t::Type{T})::Tuple{String,String} where {T<:SQLType}
  replace(t |> string, "\""=>"") |> string |> from_fully_qualified
end


function strip_module_name(s::Any)::String
  split(string(s), ".") |> last
end


function to_fully_qualified(v::String, t::String)::String
  t * "." * v
end


function to_fully_qualified(m::Type{T}, v::String)::String where {T<:AbstractModel}
  to_fully_qualified(v, table(m))
end
function to_fully_qualified(m::Type{T}, c::SQLColumn)::String where {T<:AbstractModel}
  c.raw && return c.value
  to_fully_qualified(c.value, table(m))
end


function to_sql_column_names(m::Type{T}, fields::Vector{Symbol})::Vector{Symbol} where {T<:AbstractModel}
  map(x -> (to_sql_column_name(m, string(x))) |> Symbol, fields)
end
function to_sql_column_names(m::Type{T}, fields::Tuple)::Vector{Symbol} where {T<:AbstractModel}
  to_sql_column_names(m, Symbol[fields...])
end


function to_sql_column_name(v::String, t::String)::String
  str = strip_quotes(t) * "_" * strip_quotes(v)
  if isquoted(t) && isquoted(v)
    add_quotes(str)
  else
    str
  end
end
function to_sql_column_name(m::Type{T}, v::String)::String where {T<:AbstractModel}
  to_sql_column_name(v, table(m))
end
function to_sql_column_name(m::Type{T}, c::SQLColumn)::String where {T<:AbstractModel}
  to_sql_column_name(c.value, table(m))
end


function to_fully_qualified_sql_column_names(m::Type{T}, persistable_fields::Vector{String}; escape_columns::Bool = false)::Vector{String} where {T<:AbstractModel}
  map(x -> to_fully_qualified_sql_column_name(m, x, escape_columns = escape_columns), persistable_fields)
end


function to_fully_qualified_sql_column_name(m::Type{T}, f::String; escape_columns::Bool = false, alias::String = "")::String where {T<:AbstractModel}
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


function to_dict(m::Any)::Dict{String,Any}
  Dict(string(f) => getfield(m, Symbol(f)) for f in fieldnames(typeof(m)))
end


function to_string_dict(m::T; all_fields::Bool = false, all_output::Bool = false)::Dict{String,String} where {T<:AbstractModel}
  fields = all_fields ? fieldnames(typeof(m)) : persistable_fields(typeof(m))
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


function enclosure(v::Any, o::Any)::String
  in(string(o), ["IN", "in"]) ? "($(string(v)))" : string(v)
end


function update_query_part end


function escape_column_name end


function escape_value end


function index_name(table_name::Union{String,Symbol}, column_name::Union{String,Symbol}) :: String
  string(table_name) * "__" * "idx_" * string(column_name)
end


function sql(m::Type{T}, q::SQLQuery = SQLQuery(), j::Union{Nothing,Vector{SQLJoin}} = nothing)::String where {T<:AbstractModel}
  to_fetch_sql(m, q, j)
end

function sql(m::T)::String where {T<:AbstractModel}
  to_store_sql(m)
end


### UTIL ###


"""
    add_quotes(str::String) :: String

Adds quotes around `str` and escapes any previously existing quotes.
"""
function add_quotes(str::String) :: String
  if ! startswith(str, "\"")
    str = "\"$str"
  end
  if ! endswith(str, "\"")
    str = "$str\""
  end

  str
end


"""
    strip_quotes(str::String) :: String

Unquotes `str`.
"""
function strip_quotes(str::String) :: String
  isquoted(str) ? str[2:end-1] : str
end


"""
    isquoted(str::String) :: Bool

Checks weather or not `str` is quoted.
"""
function isquoted(str::String) :: Bool
  startswith(str, "\"") && endswith(str, "\"")
end


"""
    expand_nullable{T}(value::Union{Nothing,T}, default::T) :: T

Returns `value` if it is not `nothing` - otherwise `default`.
"""
function expand_nullable(value::Union{Nothing,T}, default::T)::T where T
  value === nothing ? default : value
end


function Core.NamedTuple(p::Pair) :: NamedTuple
  @eval ($(p[1]) = $(p[2]), )
end


include("QueryBuilder.jl")

end