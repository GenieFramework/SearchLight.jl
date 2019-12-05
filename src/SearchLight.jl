module SearchLight

import Revise
import DataFrames, OrderedCollections, Distributed, Dates, Logging, Millboard

import DataFrames.DataFrame

include("constants.jl")

haskey(ENV, "SEARCHLIGHT_ENV") || (ENV["SEARCHLIGHT_ENV"] = "dev")

include("Exceptions.jl")

include(joinpath(@__DIR__, "Configuration.jl"))
using .Configuration

const config =  SearchLight.Configuration.Settings(app_env = ENV["SEARCHLIGHT_ENV"])

include("Inflector.jl")
include("FileTemplates.jl")
include("model_types.jl")
include("Database.jl")
include("Migration.jl")
include("Util.jl")
include("Validation.jl")
include("Generator.jl")
include("Highlight.jl")

import .Database, .Util, .Validation
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

const PRIMARY_KEY_NAME = "id"

if isdefined(config.db_config_settings, :serializer) && isdefined(config.db_config_settings, :serializer_path)
  include("$(config.db_config_settings.serializer_path).jl")
  Core.eval(@__MODULE__, Meta.parse("using .$(config.db_config_settings.serializer)"))
  const Serializer = Core.eval(@__MODULE__, :(config.db_config_settings.serializer))
else
  include(joinpath(@__DIR__, "serializers/JSONSerializer.jl"))
  using .JSONSerializer
  const Serializer = JSONSerializer
end

# internals


"""
"""
mutable struct UnsupportedException <: Exception
  method_name::Symbol
  adapter_name::Symbol
end

Base.showerror(io::IO, e::UnsupportedException) = print(io, "Method $(e.method_name) is not supported by $(e.adapter_name)")


#
# ORM methods
#


"""
    DataFrames.DataFrame{T<:AbstractModel, N<:AbstractModel}(m::Type{T}[, q::SQLQuery[, j::Vector{SQLJoin{N}}]])::DataFrame
    DataFrames.DataFrame{T<:AbstractModel}(m::Type{T}; order = SQLOrder(m()._id))::DataFrame

Executes a SQL `SELECT` query against the database and returns the resultset as a `DataFrame`.

# Examples
```julia
julia> DataFrame(Article)

2016-11-15T23:16:19.152 - info: SQL QUERY: SELECT articles.id AS articles_id, articles.title AS articles_title, articles.summary AS articles_summary, articles.content AS articles_content, articles.updated_at AS articles_updated_at, articles.published_at AS articles_published_at, articles.slug AS articles_slug FROM articles

  0.003031 seconds (16 allocations: 576 bytes)

32×7 DataFrames.DataFrame
│ Row │ articles_id │ articles_title                                     │ articles_summary                                                                                                                │
├─────┼─────────────┼────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 1   │ 4           │ "Possimus sit cum nesciunt doloribus dignissimos." │ "Similique.\nUt debitis qui perferendis.\nVoluptatem qui recusandae ut itaque voluptas.\nSunt."                                       │
│ 2   │ 5           │ "Voluptas ea incidunt et provident."               │ "Animi ducimus in.\nVoluptatem ipsum doloribus perspiciatis consequatur a.\nVel quibusdam quas veritatis laboriosam.\nEum quibusdam." │
...

julia> DataFrame(Article, SQLQuery(limit = 5))

2016-11-15T23:12:10.513 - info: SQL QUERY: SELECT articles.id AS articles_id, articles.title AS articles_title, articles.summary AS articles_summary, articles.content AS articles_content, articles.updated_at AS articles_updated_at, articles.published_at AS articles_published_at, articles.slug AS articles_slug FROM articles LIMIT 5

  0.000846 seconds (16 allocations: 576 bytes)

5×7 DataFrames.DataFrame
│ Row │ articles_id │ articles_title                                     │ articles_summary                                                                                                                │
├─────┼─────────────┼────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 1   │ 4           │ "Possimus sit cum nesciunt doloribus dignissimos." │ "Similique.\nUt debitis qui perferendis.\nVoluptatem qui recusandae ut itaque voluptas.\nSunt."                                       │
│ 2   │ 5           │ "Voluptas ea incidunt et provident."               │ "Animi ducimus in.\nVoluptatem ipsum doloribus perspiciatis consequatur a.\nVel quibusdam quas veritatis laboriosam.\nEum quibusdam." │
...
```
"""
function DataFrames.DataFrame(m::Type{T}, q::SQLQuery, j::Union{Nothing,Vector{SQLJoin{N}}} = nothing)::DataFrames.DataFrame where {T<:AbstractModel, N<:Union{AbstractModel,Nothing}}
  query(sql(m, q, j))::DataFrames.DataFrame
end


"""
"""
function DataFrames.DataFrame(m::Type{T}; order = SQLOrder(primary_key_name(disposable_instance(m))))::DataFrames.DataFrame where {T<:AbstractModel}
  DataFrame(m, SQLQuery(order = order))
end


"""
    DataFrames.DataFrame{T<:AbstractModel}(m::Type{T}, w::SQLWhereEntity; order = SQLOrder(m()._id))::DataFrame
    DataFrames.DataFrame{T<:AbstractModel}(m::Type{T}, w::Vector{SQLWhereEntity}; order = SQLOrder(m()._id))::DataFrame

Executes a SQL `SELECT` query against the database and returns the resultset as a `DataFrame`.

# Examples
```julia
julia> DataFrame(Article, SQLWhereExpression("id BETWEEN ? AND ?", [1, 10]))

2016-11-28T23:16:02.526 - info: SQL QUERY: SELECT articles.id AS articles_id, articles.title AS articles_title, articles.summary AS articles_summary, articles.content AS articles_content, articles.updated_at AS articles_updated_at, articles.published_at AS articles_published_at, articles.slug AS articles_slug FROM articles WHERE id BETWEEN 1 AND 10

  0.001516 seconds (16 allocations: 576 bytes)

10×7 DataFrames.DataFrame
...

julia> DataFrame(Article, SQLWhereEntity[SQLWhereExpression("id BETWEEN ? AND ?", [1, 10]), SQLWhereExpression("id >= 5")])

2016-11-28T23:14:43.496 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles" WHERE id BETWEEN 1 AND 10 AND id >= 5

  0.001202 seconds (16 allocations: 576 bytes)

6×7 DataFrames.DataFrame
...
```
"""
function DataFrames.DataFrame(m::Type{T}, w::SQLWhereEntity; order = SQLOrder(primary_key_name(disposable_instance(m))))::DataFrames.DataFrame where {T<:AbstractModel}
  DataFrame(m, SQLQuery(where = [w], order = order))
end


"""
"""
function DataFrames.DataFrame(m::Type{T}, w::Vector{SQLWhereEntity}; order = SQLOrder(primary_key_name(disposable_instance(m))))::DataFrames.DataFrame where {T<:AbstractModel}
  DataFrame(m, SQLQuery(where = w, order = order))
end


"""
"""
function DataFrames.DataFrame(args...)::DataFrames.DataFrame
  DataFrame(args...)
end


"""
    find{T<:AbstractModel, N<:AbstractModel}(m::Type{T}[, q::SQLQuery[, j::Vector{SQLJoin{N}}]])::Vector{T}
    find{T<:AbstractModel}(m::Type{T}; order = SQLOrder(m()._id))::Vector{T}

Executes a SQL `SELECT` query against the database and returns the resultset as a `Vector{T<:AbstractModel}`.

# Examples:
```julia
julia> SearchLight.find(Article, SQLQuery(where = [SQLWhereExpression("id BETWEEN ? AND ?", [10, 20])], offset = 5, limit = 5, order = :title))

2016-11-25T22:38:24.003 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles" WHERE TRUE AND id BETWEEN 10 AND 20 ORDER BY articles.title ASC LIMIT 5 OFFSET 5

  0.001486 seconds (16 allocations: 576 bytes)

5-element Array{App.Article,1}:
...

julia> SearchLight.find(Article)

2016-11-25T22:40:56.083 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles"

  0.011748 seconds (16 allocations: 576 bytes)

38-element Array{App.Article,1}:
...
```
"""
function find(m::Type{T}, q::SQLQuery, j::Union{Nothing,Vector{SQLJoin{N}}} = nothing)::Vector{T} where {T<:AbstractModel, N<:Union{Nothing,AbstractModel}}
  to_models(m, DataFrame(m, q, j))
end


"""
"""
function find(m::Type{T}, w::SQLWhereEntity;
                      order = SQLOrder(primary_key_name(disposable_instance(m))))::Vector{T} where {T<:AbstractModel}
  find(m, SQLQuery(where = [w], order = order))
end


"""
"""
function find(m::Type{T}, w::Vector{SQLWhereEntity};
                      order = SQLOrder(primary_key_name(disposable_instance(m))))::Vector{T} where {T<:AbstractModel}
  find(m, SQLQuery(where = w, order = order))
end


"""
"""
function find(m::Type{T};
                      order = SQLOrder(primary_key_name(disposable_instance(m))),
                      limit = SQLLimit(),
                      where_conditions...)::Vector{T} where {T<:AbstractModel}
  find(m, SQLQuery(where = [SQLWhereExpression("$(SQLColumn(x)) = ?", y) for (x,y) in where_conditions], order = order, limit = limit))
end


function onereduce(collection::Vector{T})::Union{Nothing,T} where {T<:AbstractModel}
  isempty(collection) ? nothing : first(collection)
end


"""
"""
function findone(m::Type{T}; filters...)::Union{Nothing,T} where {T<:AbstractModel}
  find(m; filters...) |> onereduce
end


"""
    rand{T<:AbstractModel}(m::Type{T}; limit = 1)::Vector{T}

Executes a SQL `SELECT` query against the database, `SORT`ing the results randomly and applying a `LIMIT` of `limit`.
Returns the resultset as a `Vector{T<:AbstractModel}`.

# Examples
```julia
julia> SearchLight.rand(Article)

2016-11-26T22:39:58.545 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles" ORDER BY random() ASC LIMIT 1

  0.007991 seconds (16 allocations: 576 bytes)

1-element Array{App.Article,1}:
...

julia> SearchLight.rand(Article, limit = 3)

2016-11-26T22:40:58.156 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles" ORDER BY random() ASC LIMIT 3

  0.000809 seconds (16 allocations: 576 bytes)

3-element Array{App.Article,1}:
...
```
"""
function Base.rand(m::Type{T}; limit = 1)::Vector{T} where {T<:AbstractModel}
  Database.rand(m, limit = limit)
end


"""
    randone{T<:AbstractModel}(m::Type{T})::Union{Nothing,T}

Similar to `SearchLight.rand` -- returns one random instance of {T<:AbstractModel}.

# Examples
```julia
julia> SearchLight.randone(Article)

2016-11-26T22:46:11.47100000000000003 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles" ORDER BY random() ASC LIMIT 1

  0.001087 seconds (16 allocations: 576 bytes)
...
```
"""
function randone(m::Type{T})::Union{Nothing,T} where {T<:AbstractModel}
  SearchLight.rand(m, limit = 1) |> onereduce
end


"""
    all{T<:AbstractModel}(m::Type{T})::Vector{T}

Executes a SQL `SELECT` query against the database and return all the results. Alias for `find(m)`
Returns the resultset as a `Vector{T<:AbstractModel}`.

# Examples
```julia
julia> SearchLight.all(Article)

2016-11-26T23:09:57.976 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles"

  0.003656 seconds (16 allocations: 576 bytes)

38-element Array{App.Article,1}:
...
```
"""
function Base.all(m::Type{T}; columns::Vector{SQLColumn} = SQLColumn[], order = SQLOrder(primary_key_name(disposable_instance(m))), limit::Union{Int,SQLLimit,String} = SQLLimit("ALL"), offset::Int = 0)::Vector{T} where {T<:AbstractModel}
  find(m, SQLQuery(columns = columns, order = order, limit = limit, offset = offset))
end
function Base.all(m::Type{T}, query::SQLQuery)::Vector{T} where {T<:AbstractModel}
  find(m, query)
end


"""
"""
function Base.first(m::Type{T}; order = SQLOrder(primary_key_name(disposable_instance(m))))::Union{Nothing,T} where {T<:AbstractModel}
  find(m, SQLQuery(order = order, limit = 1)) |> onereduce
end


"""
"""
function Base.last(m::Type{T}; order = SQLOrder(primary_key_name(disposable_instance(m)), :desc))::Union{Nothing,T} where {T<:AbstractModel}
  find(m, SQLQuery(order = order, limit = 1)) |> onereduce
end


# TODO: max(), min(), avg(), mean(), etc


"""
    save{T<:AbstractModel}(m::T; conflict_strategy = :error, skip_validation = false, skip_callbacks = Vector{Symbol}())::Bool

Attempts to persist the model's data to the database. Returns boolean `true` if successful, `false` otherwise.
Invokes validations and callbacks.

# Examples
```julia
julia> a = Article()

App.Article
...

julia> a.content = join(Faker.words(), " ") |> uppercasefirst
"Eaque nostrum nam"

julia> a.slug = join(Faker.words(), "-")
"quidem-sit-quas"

julia> a.title = join(Faker.words(), " ") |> uppercasefirst
"Sed vel qui"

julia> SearchLight.save(a)

2016-11-27T21:55:46.897 - info: ErrorException("SearchLight validation error(s) for App.Article \n (:title,:min_length,"title should be at least 20 chars long and it's only 11")")

julia> a.title = a.title ^ 3
"Sed vel quiSed vel quiSed vel qui"

julia> SearchLight.save(a)

2016-11-27T21:58:34.99 - info: SQL QUERY: INSERT INTO articles ( "title", "summary", "content", "updated_at", "published_at", "slug" ) VALUES ( 'Sed vel quiSed vel quiSed vel qui', '', 'Eaque nostrum nam', '2016-11-27T21:53:13.375', NULL, 'quidem-sit-quas' ) RETURNING id

  0.019713 seconds (12 allocations: 416 bytes)

true
```
"""
function save(m::T; conflict_strategy = :error, skip_validation = false, skip_callbacks = Vector{Symbol}())::Bool where {T<:AbstractModel}
  try
    _save!!(m, conflict_strategy = conflict_strategy, skip_validation = skip_validation, skip_callbacks = skip_callbacks)

    true
  catch ex
    @error ex

    false
  end
end


"""
    save!{T<:AbstractModel}(m::T; conflict_strategy = :error, skip_validation = false, skip_callbacks = Vector{Symbol}())::T
    save!!{T<:AbstractModel}(m::T; conflict_strategy = :error, skip_validation = false, skip_callbacks = Vector{Symbol}())::T

Similar to `save` but it returns the model reloaded from the database, applying callbacks. Throws an exception if the model can't be persisted.

# Examples
```julia
julia> a = Article()

App.Article
...

julia> a.content = join(Faker.paragraphs(), " ")
"Facere dolorum eum ut velit. Reiciendis at facere voluptatum neque. Est.. Et nihil et delectus veniam. Ipsum sint voluptatem voluptates. Aut necessitatibus necessitatibus.. Doloremque aspernatur maiores. Numquam facere tenetur quae. Aliquam.."

julia> a.slug = join(Faker.words(), "-")
"nulla-odit-est"

julia> a.title = Faker.paragraph()
"Sed. Consectetur. Neque tenetur sit eos.."

julia> a.title = Faker.paragraph() ^ 2
"Perspiciatis facilis perspiciatis modi. Quae natus voluptatem. Et dolor..Perspiciatis facilis perspiciatis modi. Quae natus voluptatem. Et dolor.."

julia> SearchLight.save!(a)

2016-11-27T22:12:23.295 - info: SQL QUERY: INSERT INTO articles ( "title", "summary", "content", "updated_at", "published_at", "slug" ) VALUES ( 'Perspiciatis facilis perspiciatis modi. Quae natus voluptatem. Et dolor..Perspiciatis facilis perspiciatis modi. Quae natus voluptatem. Et dolor..', '', 'Facere dolorum eum ut velit. Reiciendis at facere voluptatum neque. Est.. Et nihil et delectus veniam. Ipsum sint voluptatem voluptates. Aut necessitatibus necessitatibus.. Doloremque aspernatur maiores. Numquam facere tenetur quae. Aliquam..', '2016-11-27T22:10:23.12', NULL, 'nulla-odit-est' ) RETURNING id

  0.007109 seconds (12 allocations: 416 bytes)

2016-11-27T22:12:24.503 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles" WHERE ("id" = 43) ORDER BY articles.id ASC LIMIT 1

  0.009514 seconds (1.23 k allocations: 52.688 KB)

App.Article
...
```
"""
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


"""
    invoke_callback{T<:AbstractModel}(m::T, callback::Symbol)::Tuple{Bool,T}

Checks if the `callback` method is defined on `m` - if yes, it invokes it and returns `(true, m)`.
If not, it return `(false, m)`.

# Examples
```julia
julia> a = Articles.random()
App.Article
...

julia> SearchLight.invoke_callback(a, :before_save)
(true,
App.Article
...
)

julia> SearchLight.invoke_callback(a, :after_save)
(false,
App.Article
...
)
```
"""
function invoke_callback(m::T, callback::Symbol)::Tuple{Bool,T} where {T<:AbstractModel}
  if isdefined(m, callback)
    getfield(m, callback)(m)
    (true, m)
  else
    (false, m)
  end
end


"""
"""
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


"""
"""
function updatewith!!(m::T, w::Union{T,Dict})::T where {T<:AbstractModel}
  SearchLight.save!!(updatewith!(m, w))
end


"""

"""
function createwith(m::Type{T}, w::Dict)::T where {T<:AbstractModel}
  updatewith!(m(), w)
end


"""
"""
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


"""
    update_or_create{T<:AbstractModel}(m::T; ignore = Symbol[], skip_update = false)::T

Looks up `m` by `id` as configured in `_id`.
If `m` is already persisted, it gets updated. If not, it is persisted as a new row.
If values are provided for `ignore`, the corresponding properties (fields) of `m` will not be updated.
If `skip_update` is `true` and `m` is already persisted, no update will be performed, and the originally persisted `m` will be returned.
"""
function update_or_create(m::T; ignore = Symbol[], skip_update = false)::T where {T<:AbstractModel}
  updateby_or_create(m; ignore = ignore, skip_update = skip_update, NamedTuple{ (Symbol(primary_key_name(m)),) }( (getfield(m, Symbol(primary_key_name(m))),) )...)
end


"""
"""
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


"""
"""
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


"""
"""
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


"""
"""
function to_model!!(m::Type{T}, df::DataFrames.DataFrame; row_index = 1)::T where {T<:AbstractModel}
  dfr = DataFrames.DataFrameRow(df, row_index)

  to_model(m, dfr)
end
function to_model!!(m::Type{T}, dfr::DataFrames.DataFrameRow)::T where {T<:AbstractModel}
  to_model(m, dfr)
end


"""
    to_model{T<:AbstractModel}(m::Type{T}, df::DataFrames.DataFrame; row_index = 1)::Union{Nothing,T}

Attempts to extract row at `row_index` from `df` and convert it to an instance of `T`.

# Examples
```julia
julia> df = SearchLight.query(SearchLight.to_find_sql(Article, SQLQuery(where = [SQLWhereExpression("title LIKE ?", "%a%")], limit = 1)))

2016-12-22T14:00:34.063 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles" WHERE title LIKE '%a%' LIMIT 1

  0.000846 seconds (16 allocations: 576 bytes)

1×7 DataFrames.DataFrame
...

julia> SearchLight.to_model(Article, df)
Union{Nothing,App.Article}(
App.Article
...
)

julia> df = SearchLight.query(SearchLight.to_find_sql(Article, SQLQuery(where = [SQLWhereExpression("title LIKE ?", "%agggzgguuyyyo79%")], limit = 1)))

2016-12-22T14:02:01.938 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles" WHERE title LIKE '%agggzgguuyyyo79%' LIMIT 1

  0.000648 seconds (16 allocations: 576 bytes)

0×7 DataFrames.DataFrame

julia> SearchLight.to_model(Article, df)
Union{Nothing,App.Article}()
```
"""
function to_model(m::Type{T}, df::DataFrames.DataFrame; row_index = 1)::Union{Nothing,T} where {T<:AbstractModel}
  size(df)[1] >= row_index ? to_model!!(m, df, row_index = row_index) : nothing
end


#
# Query generation
#


"""
    to_select_part{T<:AbstractModel}(m::Type{T}, cols::Vector{SQLColumn}[, joins])::String
    to_select_part{T<:AbstractModel}(m::Type{T}, c::SQLColumn)::String
    to_select_part{T<:AbstractModel}(m::Type{T}, c::String)::String
    to_select_part{T<:AbstractModel}(m::Type{T})::String

Generates the SELECT part of the SQL query.

# Examples
```julia
julia> SearchLight.to_select_part(Article)
SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary",
  "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at",
  "articles"."slug" AS "articles_slug"

julia> SearchLight.to_select_part(Article, "id")
"SELECT articles.id AS articles_id"

julia> SearchLight.to_select_part(Article, SQLColumn(:slug))
"SELECT articles.slug AS articles_slug"

julia> SearchLight.to_select_part(Article, SQLColumn[:id, :slug, :title])
"SELECT articles.id AS articles_id, articles.slug AS articles_slug, articles.title AS articles_title"
```
"""
function to_select_part(m::Type{T}, cols::Vector{SQLColumn}, joins::Union{Nothing,Vector{SQLJoin{N}}} = nothing)::String where {T<:SearchLight.AbstractModel, N<:Union{Nothing,SearchLight.AbstractModel}}
  Database.to_select_part(m, cols, joins)
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


"""
    to_from_part{T<:AbstractModel}(m::Type{T})

Generates the FROM part of the SQL query.

# Examples
```julia
julia> SearchLight.to_from_part(Article)
"FROM "articles""
```
"""
function to_from_part(m::Type{T})::String where {T<:AbstractModel}
  Database.to_from_part(m)
end


function to_where_part(w::Vector{SQLWhereEntity})::String
  Database.to_where_part(w)
end


"""
    to_order_part{T<:AbstractModel}(m::Type{T}, o::Vector{SQLOrder})::String

Generates the ORDER part of the SQL query.

# Examples
```julia
julia> SearchLight.to_order_part(Article, SQLOrder[:id, :title])
"ORDER BY articles.id ASC, articles.title ASC"
```
"""
function to_order_part(m::Type{T}, o::Vector{SQLOrder})::String where {T<:AbstractModel}
  Database.to_order_part(m, o)
end


"""
    to_group_part(g::Vector{SQLColumn})::String

Generates the GROUP part of the SQL query.

# Examples
```julia
julia> SearchLight.to_group_part(SQLColumn[:id, :title])
" GROUP BY "id", "title" "
```
"""
function to_group_part(g::Vector{SQLColumn})::String
  Database.to_group_part(g)
end


"""
    to_limit_part(l::SQLLimit)::String
    to_limit_part(l::Int)::String

Generates the LIMIT part of the SQL query.

# Examples
```julia
julia> SearchLight.to_limit_part(SQLLimit(1))
"LIMIT 1"

julia> SearchLight.to_limit_part(1)
"LIMIT 1"
```
"""
function to_limit_part(l::SQLLimit)::String
  Database.to_limit_part(l)
end
function to_limit_part(l::Int)::String
  to_limit_part(SQLLimit(l))
end


"""
    to_offset_part(o::Int)::String

Generates the OFFSET part of the SQL query.

# Examples
```julia
julia> SearchLight.to_offset_part(10)
"OFFSET 10"
```
"""
function to_offset_part(o::Int)::String
  Database.to_offset_part(o)
end


"""
    to_having_part(h::Vector{SQLHaving})::String

Generates the HAVING part of the SQL query.

# Examples
```julia
julia> SearchLight.to_having_part(SQLHaving[SQLWhere(:aggregated_amount, 200, ">=")])
"HAVING ("aggregated_amount" >= 200)"
```
"""
function to_having_part(h::Vector{SQLWhereEntity})::String
  Database.to_having_part(h)
end


"""
    to_join_part{T<:AbstractModel}(m::Type{T}[, joins])::String

Generates the JOIN part of the SQL query.

# Examples
```julia
julia> on = SQLOn( SQLColumn("users.role_id"), SQLColumn("roles.id") )

SearchLight.SQLOn
+============+==============================================================+
|        key |                                                        value |
+============+==============================================================+
|   column_1 |                                            "users"."role_id" |
+------------+--------------------------------------------------------------+
|   column_2 |                                                 "roles"."id" |
+------------+--------------------------------------------------------------+
| conditions | Union{SearchLight.SQLWhere,SearchLight.SQLWhereExpression}[] |
+------------+--------------------------------------------------------------+


julia> j = SQLJoin(Role, on, where = SQLWhereEntity[SQLWhereExpression("role_id > 10")])

SearchLight.SQLJoin{App.Role}
+============+=============================================================+
|        key |                                                       value |
+============+=============================================================+
|    columns |                                                             |
+------------+-------------------------------------------------------------+
|  join_type |                                                       INNER |
+------------+-------------------------------------------------------------+
| model_name |                                                    App.Role |
+------------+-------------------------------------------------------------+
|    natural |                                                       false |
+------------+-------------------------------------------------------------+
|         on |                        ON "users"."role_id" = "roles"."id"  |
+------------+-------------------------------------------------------------+
|      outer |                                                       false |
+------------+-------------------------------------------------------------+
|            | Union{SearchLight.SQLWhere,SearchLight.SQLWhereExpression}[ |
|            |                              SearchLight.SQLWhereExpression |
|      where |                                                +========...]|
+------------+-------------------------------------------------------------+

julia> SearchLight.to_join_part(User, [j])
"  INNER  JOIN "roles"  ON "users"."role_id" = "roles"."id"  WHERE role_id > 10"
```
"""
function to_join_part(m::Type{T}, joins::Union{Nothing,Vector{SQLJoin{N}}} = nothing)::String where {T<:SearchLight.AbstractModel, N<:Union{Nothing,SearchLight.AbstractModel}}
  Database.to_join_part(m, joins)
end


"""
    columns_names_by_table(tables_names::Vector{String}, df::DataFrame)::Dict{String,Vector{Symbol}}

Returns the names of the columns from `df` grouped by table name -- as a `Dict` that has as keys the names of the tables from `tables_names` and as values vectors of symbols representing the names of the columns from `df`.

# Examples
```julia
julia> sql = SearchLight.to_find_sql(User, SQLQuery(limit = 1))
"SELECT "users"."id" AS "users_id", "users"."name" AS "users_name", "users"."email" AS "users_email", "users"."password" AS "users_password", "users"."role_id" AS "users_role_id", "users"."updated_at" AS "users_updated_at" FROM "users" LIMIT 1"

julia> df = SearchLight.query(sql)

2016-12-23T13:03:02.562 - info: SQL QUERY: SELECT "users"."id" AS "users_id", "users"."name" AS "users_name", "users"."email" AS "users_email", "users"."password" AS "users_password", "users"."role_id" AS "users_role_id", "users"."updated_at" AS "users_updated_at" FROM "users" LIMIT 1

  0.001819 seconds (1.23 k allocations: 52.641 KB)
1×6 DataFrames.DataFrame
│ Row │ users_id │ users_name        │ users_email        │ users_password                                                     │ users_role_id │ users_updated_at      │
├─────┼──────────┼───────────────────┼────────────────────┼────────────────────────────────────────────────────────────────────┼───────────────┼───────────────────────┤
│ 1   │ 1        │ "Adrian Salceanu" │ "e@essenciary.com" │ "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08" │ 2             │ "2016-08-25 20:05:24" │

julia> SearchLight.columns_names_by_table( ["users"], df )
Dict{String,Array{Symbol,1}} with 1 entry:
  "users" => Symbol[:users_id,:users_name,:users_email,:users_password,:users_role_id,:users_updated_at]
```
"""
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


"""
    dataframes_by_table(tables_names::Vector{String}, tables_columns::Dict{String,Vector{Symbol}}, df::DataFrame)::Dict{String,DataFrame}

Breaks a `DataFrame` into multiple dataframes by table names - one `DataFrame` corresponding to the columns of each table.
The resulting `DataFrame`s are return as a `Dict` with the keys being the table names.

# Examples
```julia
julia> sql = SearchLight.to_find_sql(User, SQLQuery(limit = 1))
"SELECT "users"."id" AS "users_id", "users"."name" AS "users_name", "users"."email" AS "users_email", "users"."password" AS "users_password", "users"."role_id" AS "users_role_id", "users"."updated_at" AS "users_updated_at" FROM "users" LIMIT 1"

julia> df = SearchLight.query(sql)

2016-12-23T13:15:19.367 - info: SQL QUERY: SELECT "users"."id" AS "users_id", "users"."name" AS "users_name", "users"."email" AS "users_email", "users"."password" AS "users_password", "users"."role_id" AS "users_role_id", "users"."updated_at" AS "users_updated_at" FROM "users" LIMIT 1

  0.001694 seconds (1.23 k allocations: 52.641 KB)
1×6 DataFrames.DataFrame
│ Row │ users_id │ users_name        │ users_email        │ users_password                                                     │ users_role_id │ users_updated_at      │
├─────┼──────────┼───────────────────┼────────────────────┼────────────────────────────────────────────────────────────────────┼───────────────┼───────────────────────┤
│ 1   │ 1        │ "Adrian Salceanu" │ "e@essenciary.com" │ "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08" │ 2             │ "2016-08-25 20:05:24" │

julia> SearchLight.dataframes_by_table(["users"], SearchLight.columns_names_by_table(["users"], df), df)
Dict{String,DataFrames.DataFrame} with 1 entry:
  "users" => 1×6 DataFrames.DataFrame…

julia> SearchLight.dataframes_by_table(["users"], SearchLight.columns_names_by_table(["users"], df), df)["users"]
1×6 DataFrames.DataFrame
│ Row │ users_id │ users_name        │ users_email        │ users_password                                                     │ users_role_id │ users_updated_at      │
├─────┼──────────┼───────────────────┼────────────────────┼────────────────────────────────────────────────────────────────────┼───────────────┼───────────────────────┤
│ 1   │ 1        │ "Adrian Salceanu" │ "e@essenciary.com" │ "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08" │ 2             │ "2016-08-25 20:05:24" │
```
"""
function dataframes_by_table(tables_names::Vector{String}, tables_columns::Dict{String,Vector{Symbol}}, df::DataFrames.DataFrame)::Dict{String,DataFrames.DataFrame}
  sub_dfs = Dict{String,DataFrames.DataFrame}()

  for t in tables_names
    sub_dfs[t] = df[:, tables_columns[t]]
  end

  sub_dfs
end
function dataframes_by_table(m::Type{T}, df::DataFrames.DataFrame)::Dict{String,DataFrames.DataFrame} where {T<:AbstractModel}
  tables_names = String[table_name(disposable_instance(m))]

  dataframes_by_table(tables_names, columns_names_by_table(tables_names, df), df)
end


"""
    to_find_sql{T<:AbstractModel,N<:AbstractModel}(m::Type{T}[, q::SQLQuery[, joins::Vector{SQLJoin{N}}]])::String

Returns the complete SELECT SQL query corresponding to `m` and `q`.

# Examples
```julia
julia> SearchLight.to_find_sql(User, SQLQuery())
"SELECT "users"."id" AS "users_id", "users"."name" AS "users_name", "users"."email" AS "users_email", "users"."password" AS "users_password", "users"."role_id" AS "users_role_id", "users"."updated_at" AS "users_updated_at", "roles"."id" AS "roles_id", "roles"."name" AS "roles_name" FROM "users" LEFT JOIN "roles" ON "users"."role_id" = "roles"."id""
```
"""
function to_find_sql(m::Type{T}, q::SQLQuery = SQLQuery(), joins::Union{Nothing,Vector{SQLJoin{N}}} = nothing)::String where {T<:AbstractModel,N<:Union{Nothing,AbstractModel}}
  Database.to_find_sql(m, q, joins)
end

const to_fetch_sql = to_find_sql

"""
    to_store_sql{T<:AbstractModel}(m::T; conflict_strategy = :error)::String

Generates the INSERT SQL query.
"""
function to_store_sql(m::T; conflict_strategy = :error)::String where {T<:AbstractModel} # upsert strateygy = :none | :error | :ignore | :update
  Database.to_store_sql(m, conflict_strategy = conflict_strategy)
end


"""
    to_sqlinput{T<:AbstractModel}(m::T, field::Symbol, value)::SQLInput

SQLInput constructor that applies various processing steps to prepare the enclosed value for database persistance (escaping, etc).
Applies `on_save` callback if defined.

# Examples
```julia
julia> SearchLight.to_sqlinput(SearchLight.findone(User, 1), :email, "adrian@example.com'; DROP users;")

2016-12-23T15:09:27.166 - info: SQL QUERY: SELECT "users"."id" AS "users_id", "users"."name" AS "users_name", "users"."email" AS "users_email", "users"."password" AS "users_password", "users"."role_id" AS "users_role_id", "users"."updated_at" AS "users_updated_at", "roles"."id" AS "roles_id", "roles"."name" AS "roles_name" FROM "users" LEFT JOIN "roles" ON "users"."role_id" = "roles"."id" WHERE ("users"."id" = 1) ORDER BY users.id ASC LIMIT 1

  0.000801 seconds (16 allocations: 576 bytes)

2016-12-23T15:09:27.173 - info: SQL QUERY: SELECT "roles"."id" AS "roles_id", "roles"."name" AS "roles_name" FROM "roles" WHERE (roles.id = 2) LIMIT 1

  0.000470 seconds (13 allocations: 432 bytes)
'adrian@example.com''; DROP users;'
```
"""
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


"""
    delete_all{T<:AbstractModel}(m::Type{T}; truncate::Bool = true, reset_sequence::Bool = true, cascade::Bool = false)::Nothing

Deletes all the rows from the database table corresponding to `m`. If `truncate` is `true`, the table will be truncated.
If `reset_sequence` is `true`, the auto-increment counter will be reset (where supported by the underlying RDBMS).
If `cascade` is `true`, the delete will be cascaded to all related tables (where supported by the underlying RDBMS).

# Examples
```julia
julia> SearchLight.delete_all(Article)
```
"""
function delete_all(m::Type{T}; truncate::Bool = true, reset_sequence::Bool = true, cascade::Bool = false)::Nothing where {T<:AbstractModel}
  Database.delete_all(m, truncate = truncate, reset_sequence = reset_sequence, cascade = cascade)
end

const deleteall = delete_all


"""
    delete{T<:AbstractModel}(m::T)::T

Deletes the database row correspoding to `m` and returns a copy of `m` that is no longer persisted.

# Examples
```julia
julia> SearchLight.delete(SearchLight.findone(Article, 61))

2016-12-23T15:29:26.997 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles" WHERE ("articles"."id" = 61) ORDER BY articles.id ASC LIMIT 1

  0.003323 seconds (1.23 k allocations: 52.688 KB)

2016-12-23T15:29:29.856 - info: SQL QUERY: DELETE FROM articles WHERE id = '61'

  0.013913 seconds (5 allocations: 176 bytes)

App.Article
...
```
"""
function delete(m::T)::T where {T<:AbstractModel}
  Database.delete(m)
end

#
# query execution
#


"""
    query(sql::String)::DataFrame

Executes the `sql` SQL query string against the underlying database.

# Examples
```julia
julia> SearchLight.query("SELECT * FROM articles LIMIT 5")

2016-12-23T15:35:58.617 - info: SQL QUERY: SELECT * FROM articles LIMIT 5

  0.117957 seconds (92.35 k allocations: 4.005 MB)

5×7 DataFrames.DataFrame
```
"""
function query(sql::String; system_query::Bool = false) :: DataFrames.DataFrame
  Database.query(sql, system_query = system_query)
end


#
# sql utility queries
#


"""
    count{T<:AbstractModel}(m::Type{T}[, q::SQLQuery = SQLQuery()])::Int

Executes a count query against `m` applying `q`.

# Examples
```julia
julia> SearchLight.count(Article)

2016-12-23T16:12:09.685 - info: SQL QUERY: SELECT COUNT(*) AS __cid FROM "articles"

  0.141865 seconds (90.51 k allocations: 3.817 MB)
49

julia> SearchLight.count(Article, SQLQuery(where = SQLWhereEntity[SQLWhereExpression("id < 10")]))

2016-12-23T16:12:48.885 - info: SQL QUERY: SELECT COUNT(*) AS __cid FROM "articles" WHERE id < 10

  0.002801 seconds (12 allocations: 416 bytes)
9
```
"""
function Base.count(m::Type{T}, q::SQLQuery = SQLQuery())::Int where {T<:AbstractModel}
  Database.count(m, q)
end


#
# ORM utils
#


"""
    disposable_instance{T<:AbstractModel}(m::Type{T})::T

Returns a type stable object T().
"""
function disposable_instance(m::Type{T})::T where {T<:AbstractModel}
  m()::T
end


"""
    clone{T<:SQLType}(o::T, fieldname::Symbol, value::Any)::T

Creates a copy of `o` changing `fieldname` with `value`.
Used to change instances of immutable types.

# Examples
```julia
julia> q = SQLQuery()

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
|   limit |                                                          ALL |
+---------+--------------------------------------------------------------+
|  offset |                                                            0 |
+---------+--------------------------------------------------------------+
|   order |                                       SearchLight.SQLOrder[] |
+---------+--------------------------------------------------------------+
|   where | Union{SearchLight.SQLWhere,SearchLight.SQLWhereExpression}[] |
+---------+--------------------------------------------------------------+


julia> q.columns = [:id, :name]
type SQLQuery is immutable

julia> SearchLight.clone(q, :columns, [:id, :name])

SearchLight.SQLQuery
+=========+==============================================================+
|     key |                                                        value |
+=========+==============================================================+
| columns |                                                 "id", "name" |
+---------+--------------------------------------------------------------+
|   group |                                                              |
+---------+--------------------------------------------------------------+
|  having | Union{SearchLight.SQLWhere,SearchLight.SQLWhereExpression}[] |
+---------+--------------------------------------------------------------+
|   limit |                                                          ALL |
+---------+--------------------------------------------------------------+
|  offset |                                                            0 |
+---------+--------------------------------------------------------------+
|   order |                                       SearchLight.SQLOrder[] |
+---------+--------------------------------------------------------------+
|   where | Union{SearchLight.SQLWhere,SearchLight.SQLWhereExpression}[] |
+---------+--------------------------------------------------------------+
```
"""
function clone(o::T, fieldname::Symbol, value::Any)::T where {T<:SQLType}
  content = Dict{Symbol,Any}()
  for field in fieldnames(typeof(o))
    content[field] = getfield(o, field)
  end
  content[fieldname] = value

  T(; content...)
end


"""
    clone{T<:SQLType}(o::T, changes::Dict{Symbol,Any})::T

Creates a copy of `o` changing `fieldname` with `value`; or replacing the corresponding properties from `o` with the corresponding values from `changes`.
Used to change instances of immutable types.
# Examples
```julia
julia> q = SQLQuery()

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
|   limit |                                                          ALL |
+---------+--------------------------------------------------------------+
|  offset |                                                            0 |
+---------+--------------------------------------------------------------+
|   order |                                       SearchLight.SQLOrder[] |
+---------+--------------------------------------------------------------+
|   where | Union{SearchLight.SQLWhere,SearchLight.SQLWhereExpression}[] |
+---------+--------------------------------------------------------------+

julia> q.limit = 2
type SQLQuery is immutable

julia> SearchLight.clone(q, Dict(:columns => [:id, :name], :limit => 10, :offset => 2))

SearchLight.SQLQuery
+=========+==============================================================+
|     key |                                                        value |
+=========+==============================================================+
| columns |                                                 "id", "name" |
+---------+--------------------------------------------------------------+
|   group |                                                              |
+---------+--------------------------------------------------------------+
|  having | Union{SearchLight.SQLWhere,SearchLight.SQLWhereExpression}[] |
+---------+--------------------------------------------------------------+
|   limit |                                                           10 |
+---------+--------------------------------------------------------------+
|  offset |                                                            2 |
+---------+--------------------------------------------------------------+
|   order |                                       SearchLight.SQLOrder[] |
+---------+--------------------------------------------------------------+
|   where | Union{SearchLight.SQLWhere,SearchLight.SQLWhereExpression}[] |
+---------+--------------------------------------------------------------+
```
"""
function clone(o::T, changes::Dict{Symbol,Any})::T where {T<:SQLType}
  content = Dict{Symbol,Any}()
  for field in fieldnames(typeof(o))
    content[field] = getfield(o, field)
  end
  content = merge(content, changes)

  T(; content...)
end


"""
    columns{T<:AbstractModel}(m::Type{T})::DataFrames.DataFrame
    columns{T<:AbstractModel}(m::T)::DataFrames.DataFrame

Returns a DataFrame representing schema information for the database table columns associated with `m`.
"""
function columns(m::Type{T})::DataFrames.DataFrame where {T<:AbstractModel}
  Database.table_columns(table_name(disposable_instance(m)))
end
function columns(m::T)::DataFrames.DataFrame where {T<:AbstractModel}
  Database.table_columns(table_name(m))
end





"""
    ispersisted{T<:AbstractModel}(m::T)::Bool

Returns wheter or not the model object is persisted to the database.

# Examples
```julia
julia> SearchLight.ispersisted(User())
false

julia> SearchLight.ispersisted(SearchLight.findone(User, 1))

2016-12-23T16:44:24.805 - info: SQL QUERY: SELECT "users"."id" AS "users_id", "users"."name" AS "users_name", "users"."email" AS "users_email", "users"."password" AS "users_password", "users"."role_id" AS "users_role_id", "users"."updated_at" AS "users_updated_at", "roles"."id" AS "roles_id", "roles"."name" AS "roles_name" FROM "users" LEFT JOIN "roles" ON "users"."role_id" = "roles"."id" WHERE ("users"."id" = 1) ORDER BY users.id ASC LIMIT 1

  0.002438 seconds (1.23 k allocations: 52.688 KB)

2016-12-23T16:44:28.13 - info: SQL QUERY: SELECT "roles"."id" AS "roles_id", "roles"."name" AS "roles_name" FROM "roles" WHERE (roles.id = 2) LIMIT 1

  0.000599 seconds (13 allocations: 432 bytes)
true
```
"""
function ispersisted(m::T)::Bool where {T<:AbstractModel}
  getfield(m, Symbol(primary_key_name(m))).value !== nothing
end


"""
    persistable_fields{T<:AbstractModel}(m::T; fully_qualified::Bool = false)::Vector{String}

Returns a vector containing the names of the fields of `m` that are mapped to corresponding database columns.
The `fully_qualified` param will prepend the name of the table and add an automatically generated alias.

# Examples
```julia
julia> SearchLight.persistable_fields(SearchLight.findone(User, 1))

2016-12-23T16:48:44.857 - info: SQL QUERY: SELECT "users"."id" AS "users_id", "users"."name" AS "users_name", "users"."email" AS "users_email", "users"."password" AS "users_password", "users"."role_id" AS "users_role_id", "users"."updated_at" AS "users_updated_at", "roles"."id" AS "roles_id", "roles"."name" AS "roles_name" FROM "users" LEFT JOIN "roles" ON "users"."role_id" = "roles"."id" WHERE ("users"."id" = 1) ORDER BY users.id ASC LIMIT 1

  0.001207 seconds (16 allocations: 576 bytes)

2016-12-23T16:48:44.872 - info: SQL QUERY: SELECT "roles"."id" AS "roles_id", "roles"."name" AS "roles_name" FROM "roles" WHERE (roles.id = 2) LIMIT 1

  0.000497 seconds (13 allocations: 432 bytes)

6-element Array{String,1}:
 "id"
 "name"
 "email"
 "password"
 "role_id"
 "updated_at"

 julia> SearchLight.persistable_fields(SearchLight.findone(User, 1), fully_qualified = true)

2016-12-23T16:49:19.066 - info: SQL QUERY: SELECT "users"."id" AS "users_id", "users"."name" AS "users_name", "users"."email" AS "users_email", "users"."password" AS "users_password", "users"."role_id" AS "users_role_id", "users"."updated_at" AS "users_updated_at", "roles"."id" AS "roles_id", "roles"."name" AS "roles_name" FROM "users" LEFT JOIN "roles" ON "users"."role_id" = "roles"."id" WHERE ("users"."id" = 1) ORDER BY users.id ASC LIMIT 1

  0.000941 seconds (16 allocations: 576 bytes)

2016-12-23T16:49:19.073 - info: SQL QUERY: SELECT "roles"."id" AS "roles_id", "roles"."name" AS "roles_name" FROM "roles" WHERE (roles.id = 2) LIMIT 1

  0.000451 seconds (13 allocations: 432 bytes)

6-element Array{String,1}:
 "users.id AS users_id"
 "users.name AS users_name"
 "users.email AS users_email"
 "users.password AS users_password"
 "users.role_id AS users_role_id"
 "users.updated_at AS users_updated_at"
```
"""
function persistable_fields(m::T; fully_qualified::Bool = false)::Vector{String} where {T<:AbstractModel}
  object_fields = map(x -> string(x), fieldnames(typeof(m)))
  db_columns =  try
                  columns(typeof(m))[!, Database.DatabaseAdapter.COLUMN_NAME_FIELD_NAME]
                catch ex
                  @error ex
                  []
                end

  pst_fields = intersect(object_fields, db_columns)

  fully_qualified ? to_fully_qualified_sql_column_names(m, pst_fields) : pst_fields
end


"""
    settable_fields{T<:AbstractModel}(m::T, row::DataFrames.DataFrameRow)::Vector{Symbol}

???
"""
function settable_fields(m::T, row::DataFrames.DataFrameRow)::Vector{Symbol} where {T<:AbstractModel}
  df_cols::Vector{Symbol} = names(row)
  fields = is_fully_qualified(m, df_cols[1]) ? to_sql_column_names(m, fieldnames(typeof(m))) : fieldnames(typeof(m))

  intersect(fields, df_cols)
end


#
# utility functions
#


"""
    id{T<:AbstractModel}(m::T)::String

Returns the "id" property defined on `m`.
"""
function id(m::T)::String where {T<:AbstractModel}
  primary_key_name(m)
end


"""
    table_name{T<:AbstractModel}(m::T)::String

Returns the table_name property defined on `m`.
"""
function table_name(m::T)::String where {T<:AbstractModel}
  if in(:_table_name, fieldnames(typeof(m)))
    m._table_name
  else
    Inflector.to_plural(string(typeof(m))) |> get |> lowercase
  end
end
function table_name(m::Type{T})::String where {T<:AbstractModel}
  table_name(disposable_instance(m))
end

const tablename = table_name


function primary_key_name(m::T)::String where {T<:AbstractModel}
  m._id
end
function primary_key_name(m::Type{T})::String where {T<:AbstractModel}
  primary_key_name(disposable_instance(m))
end

const primarykeyname = primary_key_name


"""
    validator{T<:AbstractModel}(m::T)::Union{Nothing,ModelValidator}

Gets the ModelValidator object defined for `m` wrapped in a Union{Nothing,ModelValidator}.

# Examples
```julia
julia> SearchLight.randone(Article) |> SearchLight.validator

Union{Nothing,SearchLight.ModelValidator}(
SearchLight.ModelValidator
+========+=========================================================================================================+
|    key |                                                                                                   value |
+========+=========================================================================================================+
| errors |                                                                           Tuple{Symbol,Symbol,String}[] |
+--------+---------------------------------------------------------------------------------------------------------+
|  rules | #Tuple{Symbol,Function,Vararg{Any,N}}[(:title,Validation.not_empty),(:title,Validation.min_length,20)... |
+--------+---------------------------------------------------------------------------------------------------------+
)
```
"""
function validator(m::T)::Union{Nothing,SearchLight.Validation.ModelValidator} where {T<:AbstractModel}
  Validation.validator!!(m)
end


"""
    hasfield{T<:AbstractModel}(m::T, f::Symbol)::Bool

Returns a `Bool` whether or not the field `f` is defined on the model `m`.

# Examples
```julia
julia> SearchLight.hasfield(ar, :validator)
true

julia> SearchLight.hasfield(ar, :moo)
false
```
"""
function hasfield(m::T, f::Symbol)::Bool where {T<:AbstractModel}
  isdefined(m, f)
end


"""
    strip_table_name{T<:AbstractModel}(m::T, f::Symbol)::Symbol

Strips the table name associated with the model from a fully qualified alias column name string.

# Examples
```julia
julia> SearchLight.strip_table_name(SearchLight.randone(Article), :articles_updated_at)
:updated_at
```
"""
function strip_table_name(m::T, f::Symbol)::Symbol where {T<:AbstractModel}
  replace(string(f), Regex("^$(table_name(m))_") => "", count = 1) |> Symbol
end


"""
    is_fully_qualified{T<:AbstractModel}(m::T, f::Symbol)::Bool
    is_fully_qualified{T<:SQLType}(t::T)::Bool

Returns a `Bool` whether or not `f` represents a fully qualified column name alias of the table associated with the model `m`.

# Examples
```julia
julia> SearchLight.is_fully_qualified(SearchLight.randone(Article), :articles_updated_at)
true

julia> SearchLight.is_fully_qualified(SearchLight.randone(Article), :users_updated_at)
false
```
"""
function is_fully_qualified(m::T, f::Symbol)::Bool where {T<:AbstractModel}
  startswith(string(f), table_name(m)) && hasfield(m, strip_table_name(m, f))
end
function is_fully_qualified(t::T)::Bool where {T<:SQLType}
  replace(t |> string, "\""=>"") |> string |> is_fully_qualified
end


"""
    is_fully_qualified(s::String)::Bool

Returns a `Bool` whether or not `s` represents a fully qualified SQL column name.

# Examples
```julia
julia> SearchLight.is_fully_qualified("articles.updated_at")
true

julia> SearchLight.is_fully_qualified("updated_at")
false
```
"""
function is_fully_qualified(s::String)::Bool
  ! startswith(s, ".") && occursin(".", s)
end


"""
    from_fully_qualified{T<:AbstractModel}(m::T, f::Symbol)::String

If `f` is a fully qualified column name alias of the table associated with the model `m`, it returns the column name with the table name stripped off.
Otherwise it returns `f`.

# Examples
```julia
julia> SearchLight.from_fully_qualified(SearchLight.randone(Article), :articles_updated_at)
:updated_at

julia> SearchLight.from_fully_qualified(SearchLight.randone(Article), :foo_bar)
:foo_bar
```
"""
function from_fully_qualified(m::T, f::Symbol)::Symbol where {T<:AbstractModel}
  is_fully_qualified(m, f) ? strip_table_name(m, f) : f
end


"""
    from_fully_qualified(s::String)::Tuple{String,String}

Attempts to split a fully qualified SQL column name into a Tuple of table_name and column_name.
If `s` is not in the table_name.column_name format, an error is thrown.

# Examples
```julia
julia> SearchLight.from_fully_qualified("articles.updated_at")
("articles","updated_at")

julia> SearchLight.from_fully_qualified("articles_updated_at")
------ String -------------------------- Stacktrace (most recent call last)

 [1] — from_fully_qualified(::String) at SearchLight.jl:3168

"articles_updated_at is not a fully qualified SQL column name in the format table_name.column_name"
```
"""
function from_fully_qualified(s::String)::Tuple{String,String}
  ! occursin(".", s) && throw("$s is not a fully qualified SQL column name in the format table_name.column_name")

  (x,y) = split(s, ".")

  (string(x),string(y))
end
function from_fully_qualified(t::T)::Tuple{String,String} where {T<:SQLType}
  replace(t |> string, "\""=>"") |> string |> from_fully_qualified
end


"""
    strip_module_name(s::String)::String

If `s` is in the format module_name.function_name, only the function name will be returned.
Otherwise `s` will be returned.

# Examples
```julia
julia> SearchLight.strip_module_name("SearchLight.rand")
"rand"
```
"""
function strip_module_name(s::String)::String
  split(s, ".") |> last
end


"""
    to_fully_qualified(v::String, t::String)::String

Takes `v` as the column name and `t` as the table name and returns a fully qualified SQL column name as `table_name.column_name`.

# Examples
```julia
julia> SearchLight.to_fully_qualified("updated_at", "articles")
"articles.updated_at"
```
"""
function to_fully_qualified(v::String, t::String)::String
  t * "." * v
end


"""
    to_fully_qualified{T<:AbstractModel}(m::T, v::String)::String
    to_fully_qualified{T<:AbstractModel}(m::T, c::SQLColumn)::String
    to_fully_qualified{T<:AbstractModel}(m::Type{T}, c::SQLColumn)::String

Returns the fully qualified SQL column name corresponding to the column `v` and the model `m`.

# Examples
```julia
julia> SearchLight.to_fully_qualified(SearchLight.randone(Article), "updated_at")
"articles.updated_at"
```
"""
function to_fully_qualified(m::T, v::String)::String where {T<:AbstractModel}
  to_fully_qualified(v, table_name(m))
end
function to_fully_qualified(m::T, c::SQLColumn)::String where {T<:AbstractModel}
  c.raw && return c.value
  to_fully_qualified(c.value, table_name(m))
end
function to_fully_qualified(m::Type{T}, c::SQLColumn)::String where {T<:AbstractModel}
  to_fully_qualified(disposable_instance(m), c)
end


"""
    to_sql_column_names{T<:AbstractModel}(m::T, fields::Vector{Symbol})::Vector{Symbol}

Takes a model `m` and a Vector{Symbol} corresponding to unqualified SQL column names and returns a Vector{Symbol} of fully qualified alias columns.

# Examples
```julia
julia> SearchLight.to_sql_column_names(SearchLight.randone(Article), Symbol[:updated_at, :deleted])
2-element Array{Symbol,1}:
 :articles_updated_at
 :articles_deleted
```
"""
function to_sql_column_names(m::T, fields::Vector{Symbol})::Vector{Symbol} where {T<:AbstractModel}
  map(x -> (to_sql_column_name(m, string(x))) |> Symbol, fields)
end
function to_sql_column_names(m::T, fields::Tuple)::Vector{Symbol} where {T<:AbstractModel}
  to_sql_column_names(m, Symbol[fields...])
end


"""
    to_sql_column_name(v::String, t::String)::String

Generates a column name in the form `table_column` from `t` and `v` as `t_v`.
"""
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


"""
    to_fully_qualified_sql_column_names{T<:AbstractModel}(m::T, persistable_fields::Vector{String}; escape_columns::Bool = false)::Vector{String}

Takes a `vector` of field names and generates corresponding SQL column names.
"""
function to_fully_qualified_sql_column_names(m::T, persistable_fields::Vector{String}; escape_columns::Bool = false)::Vector{String} where {T<:AbstractModel}
  map(x -> to_fully_qualified_sql_column_name(m, x, escape_columns = escape_columns), persistable_fields)
end


"""
    to_fully_qualified_sql_column_name{T<:AbstractModel}(m::T, f::String; escape_columns::Bool = false, alias::String = "")::String

Generates a fully qualified SQL column name, in the form of `table_name.column AS table_name_column` for the underlying table of `m` and the column `f`.
"""
function to_fully_qualified_sql_column_name(m::T, f::String; escape_columns::Bool = false, alias::String = "")::String where {T<:AbstractModel}
  if escape_columns
    "$(to_fully_qualified(m, f) |> escape_column_name) AS $(isempty(alias) ? (to_sql_column_name(m, f) |> escape_column_name) : alias)"
  else
    "$(to_fully_qualified(m, f)) AS $(isempty(alias) ? to_sql_column_name(m, f) : alias)"
  end
end


"""
    from_literal_column_name(c::String)::Dict{Symbol,String}

Takes a SQL column name `c` and returns a `Dict` of its parts (`:column_name`, `:alias`, `:original_string`)
"""
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


"""
    to_dict{T<:AbstractModel}(m::T; all_fields::Bool = false)::Dict{String,Any}

Converts a model `m` to a `Dict`. Orginal types of the fields values are kept.
If `all_fields` is `true`, all fields are included; otherwise just the fields corresponding to database columns.
"""
function to_dict(m::T; all_fields::Bool = false)::Dict{String,Any} where {T<:AbstractModel}
  Dict( string(f) => Util.expand_nullable( getfield(m, Symbol(f)) ) for f in (all_fields ? fieldnames(typeof(m)) : persistable_fields(m)) )
end


"""
    to_dict(m::Any)::Dict{String,Any}

Creates a `Dict` using the fields and the values of `m`.
"""
function to_dict(m::Any)::Dict{String,Any}
  Dict(string(f) => getfield(m, Symbol(f)) for f in fieldnames(typeof(m)))
end


"""
    to_string_dict{T<:AbstractModel}(m::T; all_fields::Bool = false, all_output::Bool = false)::Dict{String,String}

Converts a model `m` to a `Dict{String,String}`. Orginal types of the fields values are converted to strings.
If `all_fields` is `true`, all fields are included; otherwise just the fields corresponding to database columns.
"""
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


"""
    dataframe_to_dict(df::DataFrames.DataFrame)::Vector{Dict{Symbol,Any}}

Converts a `DataFrame` to a `Vector{Dict{Symbol,Any}}`.
"""
function dataframe_to_dict(df::DataFrames.DataFrame)::Vector{Dict{Symbol,Any}}
  result = Dict{Symbol,Any}[]
  for r in eachrow(df)
    push!(result, Dict{Symbol,Any}( [k => r[k] for k in DataFrames.names(df)] ) )
  end

  result
end


"""
    enclosure(v::Any, o::Any)::String

Wraps SQL query parts in parenthesys.
"""
function enclosure(v::Any, o::Any)::String
  in(string(o), ["IN", "in"]) ? "($(string(v)))" : string(v)
end


function update_query_part(m::T)::String where {T<:AbstractModel}
  Database.update_query_part(m)
end


"""
    create_migrations_table()::Bool

Invokes the database adapter's create migrations table method. If invoked without param, it defaults to the
database name defined in `config.db_migrations_table_name`
"""
function create_migrations_table(table_name::String = config.db_migrations_table_name) :: Bool
  Database.DatabaseAdapter.create_migrations_table(table_name)
end


"""
    init()

Initializes support for SearchLight operations - for example by creating the schema migrations table.
"""
function init() :: Bool
  create_migrations_table()
end


"""
    adapter_type(v::Bool)::Union{Bool,Int,Char,String}

Converts the Julia type to the corresponding type in the database. For example, the bool type for SQLite is 1 or 0
"""
function adapter_type(v::Bool)::Union{Bool,Int,Char,String}
  Database.DatabaseAdapter.cast_type(v)
end


"""
    function create_table()::String

Creates a new DB table
"""
function create_table(f::Function, name::String, options::String = "") :: Nothing
  sql = Database.DatabaseAdapter.create_table_sql(f, name, options)
  try
    SearchLight.query(sql)
  catch ex
    @error "Error while attempting to run: $sql"

    rethrow(ex)
  end

  nothing
end

const createtable = create_table


"""
    function column_definition(name::String, column_type::Symbol; default::Any = nothing, limit::Union{Int,Nothing} = nothing, not_null::Bool = false)::String

Returns the adapter-dependent SQL for defining a table column
"""
function column_definition(name::String, column_type::Symbol, options::String = ""; default::Any = nothing, limit::Union{Int,Nothing,String} = nothing, not_null::Bool = false)::String
  Database.DatabaseAdapter.column_sql(name, column_type, options, default = default, limit = limit, not_null = not_null)
end


"""
"""
function column_id(name::String = "id", options::String = ""; constraint::String = "", nextval::String = "")::String
  Database.DatabaseAdapter.column_id_sql(name, options, constraint = constraint, nextval = nextval)
end


"""
"""
function add_index(table_name::String, column_name::String; name::String = "", unique::Bool = false, order::Symbol = :none)::Nothing
  Database.DatabaseAdapter.add_index_sql(table_name, column_name, name = name, unique = unique, order = order) |> SearchLight.query

  nothing
end


"""
"""
function add_column(table_name::String, name::String, column_type::Symbol; default::Any = nothing, limit::Union{Int,Nothing} = nothing, not_null::Bool = false)::Nothing
  Database.DatabaseAdapter.add_column_sql(table_name, name, column_type, default = default, limit = limit, not_null = not_null) |> SearchLight.query

  nothing
end


"""
"""
function drop_table(name::String)::Nothing
  Database.DatabaseAdapter.drop_table_sql(name) |> SearchLight.query

  nothing
end


"""

"""
function remove_column(table_name::String, name::String)::Nothing
  Database.DatabaseAdapter.remove_column_sql(table_name, name) |> SearchLight.query

  nothing
end


"""
"""
function remove_index(table_name::String, name::String)::Nothing
  Database.DatabaseAdapter.remove_index_sql(table_name, name) |> SearchLight.query

  nothing
end


"""
"""
function create_sequence(name::String)::Nothing
  Database.DatabaseAdapter.create_sequence_sql(name) |> SearchLight.query

  nothing
end


"""
"""
function remove_sequence(name::String, options::String = "")::Nothing
  Database.DatabaseAdapter.remove_sequence_sql(name, options) |> SearchLight.query

  nothing
end


"""
"""
function sql(m::Type{T}, q::SQLQuery = SQLQuery(), j::Union{Nothing,Vector{SQLJoin{N}}} = nothing)::String where {T<:AbstractModel, N<:Union{Nothing,AbstractModel}}
  to_fetch_sql(m, q, j)
end
function sql(m::T)::String where {T<:AbstractModel}
  to_store_sql(m)
end


"""
    load_resources(dir = SearchLight.RESOURCES_PATH)::Nothing

Recursively adds subfolders of resources to LOAD_PATH.
"""
function load_resources(dir = SearchLight.RESOURCES_PATH)::Nothing
  ! isdir(dir) && return nothing

  res_dirs = Util.walk_dir(dir, only_dirs = true)
  ! isempty(res_dirs) && push!(LOAD_PATH, res_dirs...)

  nothing
end

const load_models = load_resources

SearchLight.load_resources()

include("QueryBuilder.jl")

end
