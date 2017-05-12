

- [Genie / SearchLight](index.md#Genie-/-SearchLight-1)

<a id='SearchLight.find_df' href='#SearchLight.find_df'>#</a>
**`SearchLight.find_df`** &mdash; *Function*.



```
find_df{T<:AbstractModel, N<:AbstractModel}(m::Type{T}[, q::SQLQuery[, j::Vector{SQLJoin{N}}]]) :: DataFrame
find_df{T<:AbstractModel}(m::Type{T}; order = SQLOrder(m()._id)) :: DataFrame
```

Executes a SQL `SELECT` query against the database and returns the resultset as a `DataFrame`.

**Examples**

```julia
julia> SearchLight.find_df(Article)

2016-11-15T23:16:19.152 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles"

  0.003031 seconds (16 allocations: 576 bytes)

32×7 DataFrames.DataFrame
│ Row │ articles_id │ articles_title                                     │ articles_summary                                                                                                                │
├─────┼─────────────┼────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 1   │ 4           │ "Possimus sit cum nesciunt doloribus dignissimos." │ "Similique.
Ut debitis qui perferendis.
Voluptatem qui recusandae ut itaque voluptas.
Sunt."                                       │
│ 2   │ 5           │ "Voluptas ea incidunt et provident."               │ "Animi ducimus in.
Voluptatem ipsum doloribus perspiciatis consequatur a.
Vel quibusdam quas veritatis laboriosam.
Eum quibusdam." │
...

julia> SearchLight.find_df(Article, SQLQuery(limit = 5))

2016-11-15T23:12:10.513 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles" LIMIT 5

  0.000846 seconds (16 allocations: 576 bytes)

5×7 DataFrames.DataFrame
│ Row │ articles_id │ articles_title                                     │ articles_summary                                                                                                                │
├─────┼─────────────┼────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 1   │ 4           │ "Possimus sit cum nesciunt doloribus dignissimos." │ "Similique.
Ut debitis qui perferendis.
Voluptatem qui recusandae ut itaque voluptas.
Sunt."                                       │
│ 2   │ 5           │ "Voluptas ea incidunt et provident."               │ "Animi ducimus in.
Voluptatem ipsum doloribus perspiciatis consequatur a.
Vel quibusdam quas veritatis laboriosam.
Eum quibusdam." │
...
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L71-L117' class='documenter-source'>source</a><br>


```
find_df{T<:AbstractModel}(m::Type{T}, w::SQLWhereEntity; order = SQLOrder(m()._id)) :: DataFrame
find_df{T<:AbstractModel}(m::Type{T}, w::Vector{SQLWhereEntity}; order = SQLOrder(m()._id)) :: DataFrame
```

Executes a SQL `SELECT` query against the database and returns the resultset as a `DataFrame`.

**Examples**

```julia
julia> SearchLight.find_df(Article, SQLWhereExpression("id BETWEEN ? AND ?", [1, 10]))

2016-11-28T23:16:02.526 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles" WHERE id BETWEEN 1 AND 10

  0.001516 seconds (16 allocations: 576 bytes)

10×7 DataFrames.DataFrame
...

julia> SearchLight.find_df(Article, SQLWhereEntity[SQLWhereExpression("id BETWEEN ? AND ?", [1, 10]), SQLWhereExpression("id >= 5")])

2016-11-28T23:14:43.496 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles" WHERE id BETWEEN 1 AND 10 AND id >= 5

  0.001202 seconds (16 allocations: 576 bytes)

6×7 DataFrames.DataFrame
...
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L117-L143' class='documenter-source'>source</a><br>

<a id='SearchLight.find' href='#SearchLight.find'>#</a>
**`SearchLight.find`** &mdash; *Function*.



```
find{T<:AbstractModel, N<:AbstractModel}(m::Type{T}[, q::SQLQuery[, j::Vector{SQLJoin{N}}]]) :: Vector{T}
find{T<:AbstractModel}(m::Type{T}; order = SQLOrder(m()._id)) :: Vector{T}
```

Executes a SQL `SELECT` query against the database and returns the resultset as a `Vector{T<:AbstractModel}`.

**Examples:**

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


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L152-L178' class='documenter-source'>source</a><br>


```
find{T<:AbstractModel}(m::Type{T}, w::SQLWhereEntity; order = SQLOrder(m()._id)) :: Vector{T}
find{T<:AbstractModel}(m::Type{T}, w::Vector{SQLWhereEntity}; order = SQLOrder(m()._id)) :: Vector{T}
```

Executes a SQL `SELECT` query against the database and returns the resultset as a `Vector{T<:AbstractModel}`.

**Examples**

```julia
julia> SearchLight.find(Article, SQLWhereExpression("id BETWEEN ? AND ?", [1, 10]))

2016-11-28T22:56:01.6880000000000001 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles" WHERE id BETWEEN 1 AND 10

  0.001705 seconds (16 allocations: 576 bytes)

10-element Array{App.Article,1}:
...

julia> SearchLight.find(Article, SQLWhereEntity[SQLWhereExpression("id BETWEEN ? AND ?", [1, 10]), SQLWhereExpression("id >= 5")])

2016-11-28T23:03:33.88 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles" WHERE id BETWEEN 1 AND 10 AND id >= 5

  0.003400 seconds (1.23 k allocations: 52.688 KB)

6-element Array{App.Article,1}:
...
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L190-L216' class='documenter-source'>source</a><br>

<a id='SearchLight.find_by' href='#SearchLight.find_by'>#</a>
**`SearchLight.find_by`** &mdash; *Function*.



```
find_by{T<:AbstractModel}(m::Type{T}, column_name::SQLColumn, value::SQLInput; order = SQLOrder(m()._id)) :: Vector{T}
find_by{T<:AbstractModel}(m::Type{T}, column_name::Any, value::Any; order = SQLOrder(m()._id)) :: Vector{T}
find_by{T<:AbstractModel}(m::Type{T}, sql_expression::SQLWhereExpression; order = SQLOrder(m()._id)) :: Vector{T}
```

Executes a SQL `SELECT` query against the database, applying a `WHERE` filter using the `column_name` and the `value`. Returns the resultset as a `Vector{T<:AbstractModel}`.

**Examples:**

```julia
julia> SearchLight.find_by(Article, :slug, "cupiditate-velit-repellat-dolorem-nobis")

2016-11-25T22:45:19.157 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles" WHERE TRUE AND ("slug" = 'cupiditate-velit-repellat-dolorem-nobis')

  0.000802 seconds (16 allocations: 576 bytes)

1-element Array{App.Article,1}:

App.Article
+==============+=========================================================+
|          key |                                                   value |
+==============+=========================================================+
|           id |                                     Nullable{Int32}(36) |
+--------------+---------------------------------------------------------+
...
+--------------+---------------------------------------------------------+
|         slug |                 cupiditate-velit-repellat-dolorem-nobis |
+--------------+---------------------------------------------------------+

julia> SearchLight.find_by(Article, SQLWhereExpression("slug LIKE ?", "%dolorem%"))

2016-11-25T23:15:52.5730000000000001 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles" WHERE TRUE AND slug LIKE '%dolorem%'

  0.000782 seconds (16 allocations: 576 bytes)

1-element Array{App.Article,1}:

App.Article
+==============+=========================================================+
|          key |                                                   value |
+==============+=========================================================+
|           id |                                     Nullable{Int32}(36) |
+--------------+---------------------------------------------------------+
...
+--------------+---------------------------------------------------------+
|         slug |                 cupiditate-velit-repellat-dolorem-nobis |
+--------------+---------------------------------------------------------+
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L225-L273' class='documenter-source'>source</a><br>

<a id='SearchLight.find_one_by' href='#SearchLight.find_one_by'>#</a>
**`SearchLight.find_one_by`** &mdash; *Function*.



```
find_one_by{T<:AbstractModel}(m::Type{T}, column_name::SQLColumn, value::SQLInput; order = SQLOrder(m()._id)) :: Nullable{T}
find_one_by{T<:AbstractModel}(m::Type{T}, column_name::Any, value::Any; order = SQLOrder(m()._id)) :: Nullable{T}
find_one_by{T<:AbstractModel}(m::Type{T}, sql_expression::SQLWhereExpression; order = SQLOrder(m()._id)) :: Nullable{T}
```

Executes a SQL `SELECT` query against the database, applying a `WHERE` filter using the `column_name` and the `value` or the `sql_expression`. Returns the first result as a `Nullable{T<:AbstractModel}`.

**Examples:**

```julia
julia> SearchLight.find_one_by(Article, :title, "Cupiditate velit repellat dolorem nobis.")

2016-11-25T23:43:13.969 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles" WHERE ("title" = 'Cupiditate velit repellat dolorem nobis.')

  0.002319 seconds (1.23 k allocations: 52.688 KB)

Nullable{App.Article}(
App.Article
+==============+=========================================================+
|          key |                                                   value |
+==============+=========================================================+
|           id |                                     Nullable{Int32}(36) |
+--------------+---------------------------------------------------------+
...
+--------------+---------------------------------------------------------+
|        title |                Cupiditate velit repellat dolorem nobis. |
+--------------+---------------------------------------------------------+

julia> SearchLight.find_one_by(Article, SQLWhereExpression("slug LIKE ?", "%nobis"))

2016-11-25T23:51:40.934 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles" WHERE slug LIKE '%nobis'

  0.001152 seconds (16 allocations: 576 bytes)

Nullable{App.Article}(
App.Article
+==============+=========================================================+
|          key |                                                   value |
+==============+=========================================================+
|           id |                                     Nullable{Int32}(36) |
+--------------+---------------------------------------------------------+
...
+--------------+---------------------------------------------------------+
|         slug |                 cupiditate-velit-repellat-dolorem-nobis |
+--------------+---------------------------------------------------------+
)

julia> SearchLight.find_one_by(Article, SQLWhereExpression("title LIKE ?", "%u%"), order = SQLOrder(:updated_at, :desc))

2016-11-26T23:00:15.638 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles" WHERE title LIKE '%u%' ORDER BY articles.updated_at DESC LIMIT 1

  0.000891 seconds (16 allocations: 576 bytes)

Nullable{App.Article}(
App.Article
+==============+================================================================================+
|          key |                                                                          value |
+==============+================================================================================+
|           id |                                                            Nullable{Int32}(19) |
+--------------+--------------------------------------------------------------------------------+
...
)

julia> SearchLight.find_one_by(Article, :title, "Id soluta officia quis quis incidunt.", order = SQLOrder(:updated_at, :desc))

2016-11-26T23:03:12.311 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles" WHERE ("title" = 'Id soluta officia quis quis incidunt.') ORDER BY articles.updated_at DESC LIMIT 1

  0.003903 seconds (1.23 k allocations: 52.688 KB)

Nullable{App.Article}(
App.Article
+==============+================================================================================+
|          key |                                                                          value |
+==============+================================================================================+
|           id |                                                            Nullable{Int32}(19) |
+--------------+--------------------------------------------------------------------------------+
...
)
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L285-L365' class='documenter-source'>source</a><br>

<a id='SearchLight.find_one_by!!' href='#SearchLight.find_one_by!!'>#</a>
**`SearchLight.find_one_by!!`** &mdash; *Function*.



```
find_one_by!!{T<:AbstractModel}(m::Type{T}, column_name::Any, value::Any; order = SQLOrder(m()._id)) :: T
find_one_by!!{T<:AbstractModel}(m::Type{T}, sql_expression::SQLWhereExpression; order = SQLOrder(m()._id)) :: T
```

Similar to `find_one_by` but also attempts to `get` the value inside the `Nullable` by means of `Base.get`. Returns the value if is not `NULL`. Throws a `NullException` otherwise.

**Examples:**

```julia
julia> SearchLight.find_one_by!!(Article, :id, 1)

2016-11-26T22:20:32.788 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles" WHERE ("id" = 1) ORDER BY articles.id ASC LIMIT 1

  0.001170 seconds (16 allocations: 576 bytes)

App.Article
+==============+===============================================================================+
|          key |                                                                         value |
+==============+===============================================================================+
|           id |                                                            Nullable{Int32}(1) |
+--------------+-------------------------------------------------------------------------------+
...

julia> SearchLight.find_one_by!!(Article, SQLWhereExpression("title LIKE ?", "%n%"))

2016-11-26T21:58:47.15 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles" WHERE title LIKE '%n%' ORDER BY articles.id ASC LIMIT 1

  0.000939 seconds (16 allocations: 576 bytes)

App.Article
+==============+===============================================================================+
|          key |                                                                         value |
+==============+===============================================================================+
|           id |                                                            Nullable{Int32}(1) |
+--------------+-------------------------------------------------------------------------------+
...
+--------------+-------------------------------------------------------------------------------+
|        title |                              Nobis provident dolor sit voluptatibus pariatur. |
+--------------+-------------------------------------------------------------------------------+

julia> SearchLight.find_one_by!!(Article, SQLWhereExpression("title LIKE ?", "foo bar baz"))

2016-11-26T21:59:39.651 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles" WHERE title LIKE 'foo bar baz' ORDER BY articles.id ASC LIMIT 1

  0.000764 seconds (16 allocations: 576 bytes)

------ NullException ------------------- Stacktrace (most recent call last)

 [1] — find_one_by!!(::Type{App.Article}, ::SearchLight.SQLWhereExpression) at SearchLight.jl:295

 [2] — |>(::Nullable{App.Article}, ::Base.#get) at operators.jl:350

 [3] — get at nullable.jl:62 [inlined]

NullException()
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L377-L433' class='documenter-source'>source</a><br>

<a id='SearchLight.find_one' href='#SearchLight.find_one'>#</a>
**`SearchLight.find_one`** &mdash; *Function*.



```
find_one{T<:AbstractModel}(m::Type{T}, value::Any) :: Nullable{T}
```

Executes a SQL `SELECT` query against the database, applying a `WHERE` filter using `SearchLight`s `_id` column and the `value`. Returns the result as a `Nullable{T<:AbstractModel}`.

**Examples**

```julia
julia> SearchLight.find_one(Article, 1)

2016-11-26T22:29:11.443 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles" WHERE ("id" = 1) ORDER BY articles.id ASC LIMIT 1

  0.000754 seconds (16 allocations: 576 bytes)

Nullable{App.Article}(
App.Article
+==============+===============================================================================+
|          key |                                                                         value |
+==============+===============================================================================+
|           id |                                                            Nullable{Int32}(1) |
+--------------+-------------------------------------------------------------------------------+
...
)
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L442-L467' class='documenter-source'>source</a><br>

<a id='SearchLight.find_one!!' href='#SearchLight.find_one!!'>#</a>
**`SearchLight.find_one!!`** &mdash; *Function*.



```
find_one!!{T<:AbstractModel}(m::Type{T}, value::Any) :: T
```

Similar to `find_one` but also attempts to get the value inside the `Nullable`. Returns the value if is not `NULL`. Throws a `NullException` otherwise.

**Examples**

```julia
julia> SearchLight.find_one!!(Article, 36)

2016-11-26T22:35:46.166 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles" WHERE ("id" = 36) ORDER BY articles.id ASC LIMIT 1

  0.000742 seconds (16 allocations: 576 bytes)

App.Article
+==============+=========================================================+
|          key |                                                   value |
+==============+=========================================================+
|           id |                                     Nullable{Int32}(36) |
+--------------+---------------------------------------------------------+
...

julia> SearchLight.find_one!!(Article, 387)

2016-11-26T22:36:22.492 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles" WHERE ("id" = 387) ORDER BY articles.id ASC LIMIT 1

  0.000915 seconds (16 allocations: 576 bytes)

------ NullException ------------------- Stacktrace (most recent call last)

 [1] — find_one!!(::Type{App.Article}, ::Int64) at SearchLight.jl:333

 [2] — |>(::Nullable{App.Article}, ::Base.#get) at operators.jl:350

 [3] — get at nullable.jl:62 [inlined]

NullException()
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L474-L512' class='documenter-source'>source</a><br>

<a id='SearchLight.rand' href='#SearchLight.rand'>#</a>
**`SearchLight.rand`** &mdash; *Function*.



```
rand{T<:AbstractModel}(m::Type{T}; limit = 1) :: Vector{T}
```

Executes a SQL `SELECT` query against the database, `SORT`ing the results randomly and applying a `LIMIT` of `limit`. Returns the resultset as a `Vector{T<:AbstractModel}`.

**Examples**

```julia
julia> SearchLight.rand(Article)

2016-11-26T22:39:58.545 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles" ORDER BY random() ASC LIMIT 1

  0.007991 seconds (16 allocations: 576 bytes)

1-element Array{App.Article,1}:

App.Article
+==============+==========================================================================================+
|          key |                                                                                    value |
+==============+==========================================================================================+
|           id |                                                                      Nullable{Int32}(16) |
+--------------+------------------------------------------------------------------------------------------+
...

julia> SearchLight.rand(Article, limit = 3)

2016-11-26T22:40:58.156 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles" ORDER BY random() ASC LIMIT 3

  0.000809 seconds (16 allocations: 576 bytes)

3-element Array{App.Article,1}:
...
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L518-L551' class='documenter-source'>source</a><br>

<a id='SearchLight.rand_one' href='#SearchLight.rand_one'>#</a>
**`SearchLight.rand_one`** &mdash; *Function*.



```
rand_one{T<:AbstractModel}(m::Type{T}) :: Nullable{T}
```

Similar to `SearchLight.rand` – returns one random instance of {T<:AbstractModel}, wrapped into a Nullable{T}.

**Examples**

```julia
julia> SearchLight.rand_one(Article)

2016-11-26T22:46:11.47100000000000003 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles" ORDER BY random() ASC LIMIT 1

  0.001087 seconds (16 allocations: 576 bytes)

Nullable{App.Article}(
App.Article
+==============+=======================================================================================+
|          key |                                                                                 value |
+==============+=======================================================================================+
|           id |                                                                   Nullable{Int32}(37) |
+--------------+---------------------------------------------------------------------------------------+
...
)
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L557-L580' class='documenter-source'>source</a><br>

<a id='SearchLight.rand_one!!' href='#SearchLight.rand_one!!'>#</a>
**`SearchLight.rand_one!!`** &mdash; *Function*.



```
rand_one!!{T<:AbstractModel}(m::Type{T}) :: T
```

Similar to `SearchLight.rand_one` – returns one random instance of {T<:AbstractModel}, but also attempts to get the object within the Nullable{T} instance. Will throw an error if Nullable{T} is null.

**Examples**

```julia
julia> ar = SearchLight.rand_one!!(Article)

App.Article
+==============+=========================================================================================================+
|          key |                                                                                                   value |
+==============+=========================================================================================================+
|           id |                                                                                     Nullable{Int32}(59) |
+--------------+---------------------------------------------------------------------------------------------------------+
...
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L586-L604' class='documenter-source'>source</a><br>

<a id='SearchLight.all' href='#SearchLight.all'>#</a>
**`SearchLight.all`** &mdash; *Function*.



```
all{T<:AbstractModel}(m::Type{T}) :: Vector{T}
```

Executes a SQL `SELECT` query against the database and return all the results. Alias for `find(m)` Returns the resultset as a `Vector{T<:AbstractModel}`.

**Examples**

```julia
julia> SearchLight.all(Article)

2016-11-26T23:09:57.976 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles"

  0.003656 seconds (16 allocations: 576 bytes)

38-element Array{App.Article,1}:
...
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L610-L627' class='documenter-source'>source</a><br>

<a id='SearchLight.save' href='#SearchLight.save'>#</a>
**`SearchLight.save`** &mdash; *Function*.



```
save{T<:AbstractModel}(m::T; conflict_strategy = :error, skip_validation = false, skip_callbacks = Vector{Symbol}()) :: Bool
```

Attempts to persist the model's data to the database. Returns boolean `true` if successful, `false` otherwise. Invokes validations and callbacks.

**Examples**

```julia
julia> a = Article()

App.Article
+==============+=========================+
|          key |                   value |
+==============+=========================+
|      content |                         |
+--------------+-------------------------+
|           id |       Nullable{Int32}() |
+--------------+-------------------------+
| published_at |    Nullable{DateTime}() |
+--------------+-------------------------+
|         slug |                         |
+--------------+-------------------------+
|      summary |                         |
+--------------+-------------------------+
|        title |                         |
+--------------+-------------------------+
|   updated_at | 2016-11-27T21:53:13.375 |
+--------------+-------------------------+

julia> a.content = join(Faker.words(), " ") |> ucfirst
"Eaque nostrum nam"

julia> a.slug = join(Faker.words(), "-")
"quidem-sit-quas"

julia> a.title = join(Faker.words(), " ") |> ucfirst
"Sed vel qui"

julia> SearchLight.save(a)

2016-11-27T21:55:46.897 - info: ErrorException("SearchLight validation error(s) for App.Article 
 (:title,:min_length,"title should be at least 20 chars long and it's only 11")")

julia> a.title = a.title ^ 3
"Sed vel quiSed vel quiSed vel qui"

julia> SearchLight.save(a)

2016-11-27T21:58:34.99 - info: SQL QUERY: INSERT INTO articles ( "title", "summary", "content", "updated_at", "published_at", "slug" ) VALUES ( 'Sed vel quiSed vel quiSed vel qui', '', 'Eaque nostrum nam', '2016-11-27T21:53:13.375', NULL, 'quidem-sit-quas' ) RETURNING id

  0.019713 seconds (12 allocations: 416 bytes)

true
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L633-L687' class='documenter-source'>source</a><br>

<a id='SearchLight.save!' href='#SearchLight.save!'>#</a>
**`SearchLight.save!`** &mdash; *Function*.



```
save!{T<:AbstractModel}(m::T; conflict_strategy = :error, skip_validation = false, skip_callbacks = Vector{Symbol}()) :: T
save!!{T<:AbstractModel}(m::T; conflict_strategy = :error, skip_validation = false, skip_callbacks = Vector{Symbol}()) :: T
```

Similar to `save` but it returns the model reloaded from the database, applying callbacks. Throws an exception if the model can't be persisted.

**Examples**

```julia
julia> a = Article()

App.Article
+==============+========================+
|          key |                  value |
+==============+========================+
|      content |                        |
+--------------+------------------------+
|           id |      Nullable{Int32}() |
+--------------+------------------------+
| published_at |   Nullable{DateTime}() |
+--------------+------------------------+
|         slug |                        |
+--------------+------------------------+
|      summary |                        |
+--------------+------------------------+
|        title |                        |
+--------------+------------------------+
|   updated_at | 2016-11-27T22:10:23.12 |
+--------------+------------------------+

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
+==============+=========================================================================================================+
|          key |                                                                                                   value |
+==============+=========================================================================================================+
|      content | Facere dolorum eum ut velit. Reiciendis at facere voluptatum neque. Est.. Et nihil et delectus venia... |
+--------------+---------------------------------------------------------------------------------------------------------+
|           id |                                                                                     Nullable{Int32}(43) |
+--------------+---------------------------------------------------------------------------------------------------------+
| published_at |                                                                                    Nullable{DateTime}() |
+--------------+---------------------------------------------------------------------------------------------------------+
|         slug |                                                                                          nulla-odit-est |
+--------------+---------------------------------------------------------------------------------------------------------+
|      summary |                                                                                                         |
+--------------+---------------------------------------------------------------------------------------------------------+
|        title | Perspiciatis facilis perspiciatis modi. Quae natus voluptatem. Et dolor..Perspiciatis facilis perspi... |
+--------------+---------------------------------------------------------------------------------------------------------+
|   updated_at |                                                                                  2016-11-27T22:10:23.12 |
+--------------+---------------------------------------------------------------------------------------------------------+
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L701-L771' class='documenter-source'>source</a><br>

<a id='SearchLight.invoke_callback' href='#SearchLight.invoke_callback'>#</a>
**`SearchLight.invoke_callback`** &mdash; *Function*.



```
invoke_callback{T<:AbstractModel}(m::T, callback::Symbol) :: Tuple{Bool,T}
```

Checks if the `callback` method is defined on `m` - if yes, it invokes it and returns `(true, m)`. If not, it return `(false, m)`.

**Examples**

```julia
julia> a = Articles.random()

App.Article
+==============+=========================================================================================================+
|          key |                                                                                                   value |
+==============+=========================================================================================================+
|           id |                                                                                       Nullable{Int32}() |
+--------------+---------------------------------------------------------------------------------------------------------+
...

julia> SearchLight.invoke_callback(a, :before_save)
(true,
App.Article
+==============+=========================================================================================================+
|          key |                                                                                                   value |
+==============+=========================================================================================================+
|           id |                                                                                       Nullable{Int32}() |
+--------------+---------------------------------------------------------------------------------------------------------+
...
)

julia> SearchLight.invoke_callback(a, :after_save)
(false,
App.Article
+==============+=========================================================================================================+
|          key |                                                                                                   value |
+==============+=========================================================================================================+
|           id |                                                                                       Nullable{Int32}() |
+--------------+---------------------------------------------------------------------------------------------------------+
...
)
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L792-L832' class='documenter-source'>source</a><br>

<a id='SearchLight.update_with!' href='#SearchLight.update_with!'>#</a>
**`SearchLight.update_with!`** &mdash; *Function*.



```
update_with!{T<:AbstractModel}(m::T, w::T) :: T
update_with!{T<:AbstractModel}(m::T, w::Dict) :: T
```

Copies the data from `w` into the corresponding properties in `m`. Returns `m`.

**Examples**

```julia
julia> a = Articles.random()

App.Article
+==============+=========================================================================================================+
|          key |                                                                                                   value |
+==============+=========================================================================================================+
|      content | Iusto et vel aut minima molestias. Debitis maiores magnam repellat. Eos totam blanditiis..Iusto et v... |
+--------------+---------------------------------------------------------------------------------------------------------+
|           id |                                                                                       Nullable{Int32}() |
+--------------+---------------------------------------------------------------------------------------------------------+
| published_at |                                                                                    Nullable{DateTime}() |
+--------------+---------------------------------------------------------------------------------------------------------+
|         slug |    at-omnis-maxime-corrupti-omnis-dignissimos-ducimusat-omnis-maxime-corrupti-omnis-dignissimos-ducimus |
+--------------+---------------------------------------------------------------------------------------------------------+
|      summary |    Iusto et vel aut minima molestias. Debitis maiores magnam repellat. Eos totam blanditiis..Iusto et v |
+--------------+---------------------------------------------------------------------------------------------------------+
|        title | At omnis maxime. Corrupti omnis dignissimos ducimus..At omnis maxime. Corrupti omnis dignissimos duc... |
+--------------+---------------------------------------------------------------------------------------------------------+
|   updated_at |                                                                    2016-11-27T23:11:27.7010000000000001 |
+--------------+---------------------------------------------------------------------------------------------------------+

julia> b = Article()

App.Article
+==============+=========================+
|          key |                   value |
+==============+=========================+
|      content |                         |
+--------------+-------------------------+
|           id |       Nullable{Int32}() |
+--------------+-------------------------+
| published_at |    Nullable{DateTime}() |
+--------------+-------------------------+
|         slug |                         |
+--------------+-------------------------+
|      summary |                         |
+--------------+-------------------------+
|        title |                         |
+--------------+-------------------------+
|   updated_at | 2016-11-27T23:11:35.628 |
+--------------+-------------------------+

julia> SearchLight.update_with!(b, a)

App.Article
+==============+=========================================================================================================+
|          key |                                                                                                   value |
+==============+=========================================================================================================+
|      content | Iusto et vel aut minima molestias. Debitis maiores magnam repellat. Eos totam blanditiis..Iusto et v... |
+--------------+---------------------------------------------------------------------------------------------------------+
|           id |                                                                                       Nullable{Int32}() |
+--------------+---------------------------------------------------------------------------------------------------------+
| published_at |                                                                                    Nullable{DateTime}() |
+--------------+---------------------------------------------------------------------------------------------------------+
|         slug |    at-omnis-maxime-corrupti-omnis-dignissimos-ducimusat-omnis-maxime-corrupti-omnis-dignissimos-ducimus |
+--------------+---------------------------------------------------------------------------------------------------------+
|      summary |    Iusto et vel aut minima molestias. Debitis maiores magnam repellat. Eos totam blanditiis..Iusto et v |
+--------------+---------------------------------------------------------------------------------------------------------+
|        title | At omnis maxime. Corrupti omnis dignissimos ducimus..At omnis maxime. Corrupti omnis dignissimos duc... |
+--------------+---------------------------------------------------------------------------------------------------------+
|   updated_at |                                                                    2016-11-27T23:11:27.7010000000000001 |
+--------------+---------------------------------------------------------------------------------------------------------+

julia> b

App.Article
+==============+=========================================================================================================+
|          key |                                                                                                   value |
+==============+=========================================================================================================+
|      content | Iusto et vel aut minima molestias. Debitis maiores magnam repellat. Eos totam blanditiis..Iusto et v... |
+--------------+---------------------------------------------------------------------------------------------------------+
|           id |                                                                                       Nullable{Int32}() |
+--------------+---------------------------------------------------------------------------------------------------------+
| published_at |                                                                                    Nullable{DateTime}() |
+--------------+---------------------------------------------------------------------------------------------------------+
|         slug |    at-omnis-maxime-corrupti-omnis-dignissimos-ducimusat-omnis-maxime-corrupti-omnis-dignissimos-ducimus |
+--------------+---------------------------------------------------------------------------------------------------------+
|      summary |    Iusto et vel aut minima molestias. Debitis maiores magnam repellat. Eos totam blanditiis..Iusto et v |
+--------------+---------------------------------------------------------------------------------------------------------+
|        title | At omnis maxime. Corrupti omnis dignissimos ducimus..At omnis maxime. Corrupti omnis dignissimos duc... |
+--------------+---------------------------------------------------------------------------------------------------------+
|   updated_at |                                                                    2016-11-27T23:11:27.7010000000000001 |
+--------------+---------------------------------------------------------------------------------------------------------+

julia> d = Articles.random() |> SearchLight.to_dict
Dict{String,Any} with 7 entries:
  "summary"      => "Culpa quam quod. Iusto..Culpa quam quod. Iusto..Culpa quam quod. Iusto..Culpa quam quod. Iusto..Culp"
  "content"      => "Culpa quam quod. Iusto..Culpa quam quod. Iusto..Culpa quam quod. Iusto..Culpa quam quod. Iusto..Culpa quam quod. Iusto..Culpa quam quod. Iusto..Culpa quam quod. Iusto..Culpa quam quod. Iusto..Culpa quam quod. Iusto..…
  "id"           => #NULL
  "title"        => "Minima. Eius. Velit. Sunt ducimus cumque eveniet..Minima. Eius. Velit. Sunt ducimus cumque eveniet.."
  "updated_at"   => 2016-11-27T23:17:55.379
  "slug"         => "minima-eius-velit-sunt-ducimus-cumque-evenietminima-eius-velit-sunt-ducimus-cumque-eveniet"
  "published_at" => #NULL

julia> a = Article()

App.Article
+==============+=========================+
|          key |                   value |
+==============+=========================+
|      content |                         |
+--------------+-------------------------+
|           id |       Nullable{Int32}() |
+--------------+-------------------------+
| published_at |    Nullable{DateTime}() |
+--------------+-------------------------+
|         slug |                         |
+--------------+-------------------------+
|      summary |                         |
+--------------+-------------------------+
|        title |                         |
+--------------+-------------------------+
|   updated_at | 2016-11-27T23:18:06.438 |
+--------------+-------------------------+

julia> SearchLight.update_with!(a, d)

App.Article
+==============+=========================================================================================================+
|          key |                                                                                                   value |
+==============+=========================================================================================================+
|      content | Culpa quam quod. Iusto..Culpa quam quod. Iusto..Culpa quam quod. Iusto..Culpa quam quod. Iusto..Culp... |
+--------------+---------------------------------------------------------------------------------------------------------+
|           id |                                                                                       Nullable{Int32}() |
+--------------+---------------------------------------------------------------------------------------------------------+
| published_at |                                                                                    Nullable{DateTime}() |
+--------------+---------------------------------------------------------------------------------------------------------+
|         slug |              minima-eius-velit-sunt-ducimus-cumque-evenietminima-eius-velit-sunt-ducimus-cumque-eveniet |
+--------------+---------------------------------------------------------------------------------------------------------+
|      summary |    Culpa quam quod. Iusto..Culpa quam quod. Iusto..Culpa quam quod. Iusto..Culpa quam quod. Iusto..Culp |
+--------------+---------------------------------------------------------------------------------------------------------+
|        title |    Minima. Eius. Velit. Sunt ducimus cumque eveniet..Minima. Eius. Velit. Sunt ducimus cumque eveniet.. |
+--------------+---------------------------------------------------------------------------------------------------------+
|   updated_at |                                                                                 2016-11-27T23:17:55.379 |
+--------------+---------------------------------------------------------------------------------------------------------+
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L843-L987' class='documenter-source'>source</a><br>

<a id='SearchLight.update_with!!' href='#SearchLight.update_with!!'>#</a>
**`SearchLight.update_with!!`** &mdash; *Function*.



```
update_with!!{T<:AbstractModel}(m::T, w::Union{T,Dict}) :: T
```

Similar to `update_with` but also calls `save!!` on `m`.

**Examples**

```julia
julia> d = Articles.random() |> SearchLight.to_dict
Dict{String,Any} with 7 entries:
  "summary"      => "Suscipit beatae vitae. Eum accusamus ad. Nostrum nam excepturi rerum suscipit..Suscipit beatae vitae"
  "content"      => "Suscipit beatae vitae. Eum accusamus ad. Nostrum nam excepturi rerum suscipit..Suscipit beatae vitae. Eum accusamus ad. Nostrum nam excepturi rerum suscipit..Suscipit beatae vitae. Eum accusamus ad. Nostrum nam excep…
  "id"           => #NULL
  "title"        => "Impedit ut nulla sed. Sint sed dolorum quas beatae aspernatur..Impedit ut nulla sed. Sint sed dolorum quas beatae aspernatur.."
  "updated_at"   => 2016-11-27T23:24:20.062
  "slug"         => "impedit-ut-nulla-sed-sint-sed-dolorum-quas-beatae-aspernaturimpedit-ut-nulla-sed-sint-sed-dolorum-quas-beatae-aspernatur"
  "published_at" => #NULL

julia> a = Article()

App.Article
+==============+=========================+
|          key |                   value |
+==============+=========================+
|      content |                         |
+--------------+-------------------------+
|           id |       Nullable{Int32}() |
+--------------+-------------------------+
| published_at |    Nullable{DateTime}() |
+--------------+-------------------------+
|         slug |                         |
+--------------+-------------------------+
|      summary |                         |
+--------------+-------------------------+
|        title |                         |
+--------------+-------------------------+
|   updated_at | 2016-11-27T23:24:25.494 |
+--------------+-------------------------+

julia> SearchLight.update_with!!(a, d)

2016-11-27T23:24:31.105 - info: SQL QUERY: INSERT INTO articles ( "title", "summary", "content", "updated_at", "published_at", "slug" ) VALUES ( 'Impedit ut nulla sed. Sint sed dolorum quas beatae aspernatur..Impedit ut nulla sed. Sint sed dolorum quas beatae aspernatur..', 'Suscipit beatae vitae. Eum accusamus ad. Nostrum nam excepturi rerum suscipit..Suscipit beatae vitae', 'Suscipit beatae vitae. Eum accusamus ad. Nostrum nam excepturi rerum suscipit..Suscipit beatae vitae. Eum accusamus ad. Nostrum nam excepturi rerum suscipit..Suscipit beatae vitae. Eum accusamus ad. Nostrum nam excepturi rerum suscipit..Suscipit beatae vitae. Eum accusamus ad. Nostrum nam excepturi rerum suscipit..Suscipit beatae vitae. Eum accusamus ad. Nostrum nam excepturi rerum suscipit..Suscipit beatae vitae. Eum accusamus ad. Nostrum nam excepturi rerum suscipit..Suscipit beatae vitae. Eum accusamus ad. Nostrum nam excepturi rerum suscipit..Suscipit beatae vitae. Eum accusamus ad. Nostrum nam excepturi rerum suscipit..Suscipit beatae vitae. Eum accusamus ad. Nostrum nam excepturi rerum suscipit..Suscipit beatae vitae. Eum accusamus ad. Nostrum nam excepturi rerum suscipit..', '2016-11-27T23:24:20.062', NULL, 'impedit-ut-nulla-sed-sint-sed-dolorum-quas-beatae-aspernaturimpedit-ut-nulla-sed-sint-sed-dolorum-quas-beatae-aspernatur' ) RETURNING id

  0.008251 seconds (12 allocations: 416 bytes)

2016-11-27T23:24:32.274 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles" WHERE ("id" = 60) ORDER BY articles.id ASC LIMIT 1

  0.003159 seconds (1.23 k allocations: 52.688 KB)

App.Article
+==============+=========================================================================================================+
|          key |                                                                                                   value |
+==============+=========================================================================================================+
|      content | Suscipit beatae vitae. Eum accusamus ad. Nostrum nam excepturi rerum suscipit..Suscipit beatae vitae... |
+--------------+---------------------------------------------------------------------------------------------------------+
|           id |                                                                                     Nullable{Int32}(60) |
+--------------+---------------------------------------------------------------------------------------------------------+
| published_at |                                                                                    Nullable{DateTime}() |
+--------------+---------------------------------------------------------------------------------------------------------+
|         slug | impedit-ut-nulla-sed-sint-sed-dolorum-quas-beatae-aspernaturimpedit-ut-nulla-sed-sint-sed-dolorum-qu... |
+--------------+---------------------------------------------------------------------------------------------------------+
|      summary |    Suscipit beatae vitae. Eum accusamus ad. Nostrum nam excepturi rerum suscipit..Suscipit beatae vitae |
+--------------+---------------------------------------------------------------------------------------------------------+
|        title | Impedit ut nulla sed. Sint sed dolorum quas beatae aspernatur..Impedit ut nulla sed. Sint sed doloru... |
+--------------+---------------------------------------------------------------------------------------------------------+
|   updated_at |                                                                                 2016-11-27T23:24:20.062 |
+--------------+---------------------------------------------------------------------------------------------------------+
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L1027-L1094' class='documenter-source'>source</a><br>

<a id='SearchLight.create_with' href='#SearchLight.create_with'>#</a>
**`SearchLight.create_with`** &mdash; *Function*.





<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L1100-L1102' class='documenter-source'>source</a><br>

<a id='SearchLight.update_by_or_create!!' href='#SearchLight.update_by_or_create!!'>#</a>
**`SearchLight.update_by_or_create!!`** &mdash; *Function*.



```
update_by_or_create!!{T<:AbstractModel}(m::T, property::Symbol[, value::Any]) :: T
```

Looks up `m` by `property` and `value`. If value is not provided, it uses the corresponding value of `m`. If `m` is already persisted, it gets updated. If not, it is persisted as a new row.

**Examples**

```julia
julia> a = Articles.random()

App.Article
+==============+=========================================================================================================+
|          key |                                                                                                   value |
+==============+=========================================================================================================+
|      content | Pariatur maiores. Amet numquam ullam nostrum est. Excepturi..Pariatur maiores. Amet numquam ullam no... |
+--------------+---------------------------------------------------------------------------------------------------------+
|           id |                                                                                       Nullable{Int32}() |
+--------------+---------------------------------------------------------------------------------------------------------+
| published_at |                                                                                    Nullable{DateTime}() |
+--------------+---------------------------------------------------------------------------------------------------------+
|         slug | neque-repudiandae-sit-vel-laudantium-laboriosam-in-esse-modi-autem-ut-asperioresneque-repudiandae-si... |
+--------------+---------------------------------------------------------------------------------------------------------+
|      summary |    Pariatur maiores. Amet numquam ullam nostrum est. Excepturi..Pariatur maiores. Amet numquam ullam no |
+--------------+---------------------------------------------------------------------------------------------------------+
|        title | Neque repudiandae sit vel. Laudantium laboriosam in. Esse modi autem ut asperiores..Neque repudianda... |
+--------------+---------------------------------------------------------------------------------------------------------+
|   updated_at |                                                                                 2016-11-28T22:18:48.723 |
+--------------+---------------------------------------------------------------------------------------------------------+


julia> SearchLight.update_by_or_create!!(a, :slug)

2016-11-28T22:19:39.094 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles" WHERE ("slug" = 'neque-repudiandae-sit-vel-laudantium-laboriosam-in-esse-modi-autem-ut-asperioresneque-repudiandae-sit-vel-laudantium-laboriosam-in-esse-modi-aut') ORDER BY articles.id ASC LIMIT 1

  0.019534 seconds (1.23 k allocations: 52.688 KB)

2016-11-28T22:19:40.056 - info: SQL QUERY: INSERT INTO articles ( "title", "summary", "content", "updated_at", "published_at", "slug" ) VALUES ( 'Neque repudiandae sit vel. Laudantium laboriosam in. Esse modi autem ut asperiores..Neque repudiandae sit vel. Laudantium laboriosam in. Esse modi aut', 'Pariatur maiores. Amet numquam ullam nostrum est. Excepturi..Pariatur maiores. Amet numquam ullam no', 'Pariatur maiores. Amet numquam ullam nostrum est. Excepturi..Pariatur maiores. Amet numquam ullam nostrum est. Excepturi..Pariatur maiores. Amet numquam ullam nostrum est. Excepturi..Pariatur maiores. Amet numquam ullam nostrum est. Excepturi..Pariatur maiores. Amet numquam ullam nostrum est. Excepturi..Pariatur maiores. Amet numquam ullam nostrum est. Excepturi..Pariatur maiores. Amet numquam ullam nostrum est. Excepturi..Pariatur maiores. Amet numquam ullam nostrum est. Excepturi..Pariatur maiores. Amet numquam ullam nostrum est. Excepturi..Pariatur maiores. Amet numquam ullam nostrum est. Excepturi..', '2016-11-28T22:18:48.723', NULL, 'neque-repudiandae-sit-vel-laudantium-laboriosam-in-esse-modi-autem-ut-asperioresneque-repudiandae-sit-vel-laudantium-laboriosam-in-esse-modi-aut' ) RETURNING id

  0.008992 seconds (12 allocations: 416 bytes)

2016-11-28T22:19:40.158 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles" WHERE ("id" = 61) ORDER BY articles.id ASC LIMIT 1

  0.000747 seconds (16 allocations: 576 bytes)

App.Article
+==============+=========================================================================================================+
|          key |                                                                                                   value |
+==============+=========================================================================================================+
|      content | Pariatur maiores. Amet numquam ullam nostrum est. Excepturi..Pariatur maiores. Amet numquam ullam no... |
+--------------+---------------------------------------------------------------------------------------------------------+
|           id |                                                                                     Nullable{Int32}(61) |
+--------------+---------------------------------------------------------------------------------------------------------+
| published_at |                                                                                    Nullable{DateTime}() |
+--------------+---------------------------------------------------------------------------------------------------------+
|         slug | neque-repudiandae-sit-vel-laudantium-laboriosam-in-esse-modi-autem-ut-asperioresneque-repudiandae-si... |
+--------------+---------------------------------------------------------------------------------------------------------+
|      summary |    Pariatur maiores. Amet numquam ullam nostrum est. Excepturi..Pariatur maiores. Amet numquam ullam no |
+--------------+---------------------------------------------------------------------------------------------------------+
|        title | Neque repudiandae sit vel. Laudantium laboriosam in. Esse modi autem ut asperiores..Neque repudianda... |
+--------------+---------------------------------------------------------------------------------------------------------+
|   updated_at |                                                                                 2016-11-28T22:18:48.723 |
+--------------+---------------------------------------------------------------------------------------------------------+

julia> a.summary = Faker.paragraph() ^ 2
"Similique sunt. Cupiditate eligendi..Similique sunt. Cupiditate eligendi.."

julia> SearchLight.update_by_or_create!!(a, :slug)

2016-11-28T22:22:22.488 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles" WHERE ("slug" = 'neque-repudiandae-sit-vel-laudantium-laboriosam-in-esse-modi-autem-ut-asperioresneque-repudiandae-sit-vel-laudantium-laboriosam-in-esse-modi-aut') ORDER BY articles.id ASC LIMIT 1

  0.000949 seconds (16 allocations: 576 bytes)

2016-11-28T22:22:22.556 - info: SQL QUERY: UPDATE articles SET  "id" = 61, "title" = 'Neque repudiandae sit vel. Laudantium laboriosam in. Esse modi autem ut asperiores..Neque repudiandae sit vel. Laudantium laboriosam in. Esse modi aut', "summary" = 'Similique sunt. Cupiditate eligendi..Similique sunt. Cupiditate eligendi..', "content" = 'Pariatur maiores. Amet numquam ullam nostrum est. Excepturi..Pariatur maiores. Amet numquam ullam nostrum est. Excepturi..Pariatur maiores. Amet numquam ullam nostrum est. Excepturi..Pariatur maiores. Amet numquam ullam nostrum est. Excepturi..Pariatur maiores. Amet numquam ullam nostrum est. Excepturi..Pariatur maiores. Amet numquam ullam nostrum est. Excepturi..Pariatur maiores. Amet numquam ullam nostrum est. Excepturi..Pariatur maiores. Amet numquam ullam nostrum est. Excepturi..Pariatur maiores. Amet numquam ullam nostrum est. Excepturi..Pariatur maiores. Amet numquam ullam nostrum est. Excepturi..', "updated_at" = '2016-11-28T22:18:48.723', "published_at" = NULL, "slug" = 'neque-repudiandae-sit-vel-laudantium-laboriosam-in-esse-modi-autem-ut-asperioresneque-repudiandae-sit-vel-laudantium-laboriosam-in-esse-modi-aut' WHERE articles.id = '61' RETURNING id

  0.009145 seconds (12 allocations: 416 bytes)

2016-11-28T22:22:22.5670000000000001 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles" WHERE ("id" = 61) ORDER BY articles.id ASC LIMIT 1

  0.000741 seconds (16 allocations: 576 bytes)

App.Article
+==============+=========================================================================================================+
|          key |                                                                                                   value |
+==============+=========================================================================================================+
|      content | Pariatur maiores. Amet numquam ullam nostrum est. Excepturi..Pariatur maiores. Amet numquam ullam no... |
+--------------+---------------------------------------------------------------------------------------------------------+
|           id |                                                                                     Nullable{Int32}(61) |
+--------------+---------------------------------------------------------------------------------------------------------+
| published_at |                                                                                    Nullable{DateTime}() |
+--------------+---------------------------------------------------------------------------------------------------------+
|         slug | neque-repudiandae-sit-vel-laudantium-laboriosam-in-esse-modi-autem-ut-asperioresneque-repudiandae-si... |
+--------------+---------------------------------------------------------------------------------------------------------+
|      summary |                              Similique sunt. Cupiditate eligendi..Similique sunt. Cupiditate eligendi.. |
+--------------+---------------------------------------------------------------------------------------------------------+
|        title | Neque repudiandae sit vel. Laudantium laboriosam in. Esse modi autem ut asperiores..Neque repudianda... |
+--------------+---------------------------------------------------------------------------------------------------------+
|   updated_at |                                                                                 2016-11-28T22:18:48.723 |
+--------------+---------------------------------------------------------------------------------------------------------+
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L1108-L1207' class='documenter-source'>source</a><br>

<a id='SearchLight.find_one_by_or_create' href='#SearchLight.find_one_by_or_create'>#</a>
**`SearchLight.find_one_by_or_create`** &mdash; *Function*.



```
find_one_by_or_create{T<:AbstractModel}(m::Type{T}, property::Any, value::Any) :: T
```

Looks up `m` by `property` and `value`. If it exists, it is returned. If not, a new instance is created, `property` is set to `value` and the instance is returned.

**Examples**

```julia
julia> SearchLight.find_one_by_or_create(Article, :slug, SearchLight.find_one!!(Article, 61).slug)

2016-11-28T22:31:56.768 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles" WHERE ("id" = 61) ORDER BY articles.id ASC LIMIT 1

  0.003430 seconds (1.23 k allocations: 52.688 KB)

2016-11-28T22:31:59.897 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles" WHERE ("slug" = 'neque-repudiandae-sit-vel-laudantium-laboriosam-in-esse-modi-autem-ut-asperioresneque-repudiandae-sit-vel-laudantium-laboriosam-in-esse-modi-aut') ORDER BY articles.id ASC LIMIT 1

  0.001069 seconds (16 allocations: 576 bytes)

App.Article
+==============+=========================================================================================================+
|          key |                                                                                                   value |
+==============+=========================================================================================================+
|      content | Pariatur maiores. Amet numquam ullam nostrum est. Excepturi..Pariatur maiores. Amet numquam ullam no... |
+--------------+---------------------------------------------------------------------------------------------------------+
|           id |                                                                                     Nullable{Int32}(61) |
+--------------+---------------------------------------------------------------------------------------------------------+
| published_at |                                                                                    Nullable{DateTime}() |
+--------------+---------------------------------------------------------------------------------------------------------+
|         slug | neque-repudiandae-sit-vel-laudantium-laboriosam-in-esse-modi-autem-ut-asperioresneque-repudiandae-si... |
+--------------+---------------------------------------------------------------------------------------------------------+
|      summary |                              Similique sunt. Cupiditate eligendi..Similique sunt. Cupiditate eligendi.. |
+--------------+---------------------------------------------------------------------------------------------------------+
|        title | Neque repudiandae sit vel. Laudantium laboriosam in. Esse modi autem ut asperiores..Neque repudianda... |
+--------------+---------------------------------------------------------------------------------------------------------+
|   updated_at |                                                                                 2016-11-28T22:18:48.723 |
+--------------+---------------------------------------------------------------------------------------------------------+


julia> SearchLight.find_one_by_or_create(Article, :slug, "foo-bar")

2016-11-28T22:32:19.514 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles" WHERE ("slug" = 'foo-bar') ORDER BY articles.id ASC LIMIT 1

  0.000909 seconds (16 allocations: 576 bytes)

App.Article
+==============+=========================+
|          key |                   value |
+==============+=========================+
|      content |                         |
+--------------+-------------------------+
|           id |       Nullable{Int32}() |
+--------------+-------------------------+
| published_at |    Nullable{DateTime}() |
+--------------+-------------------------+
|         slug |                 foo-bar |
+--------------+-------------------------+
|      summary |                         |
+--------------+-------------------------+
|        title |                         |
+--------------+-------------------------+
|   updated_at | 2016-11-28T22:32:19.518 |
+--------------+-------------------------+
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L1228-L1291' class='documenter-source'>source</a><br>

<a id='SearchLight.to_models' href='#SearchLight.to_models'>#</a>
**`SearchLight.to_models`** &mdash; *Function*.



to_models{T<:AbstractModel}(m::Type{T}, df::DataFrames.DataFrame) :: Vector{T}

Converts a DataFrame `df` to a Vector{T}

**Examples**

```julia
julia> sql = SearchLight.to_fetch_sql(Article, SQLQuery(limit = 1))
"SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles" LIMIT 1"

julia> df = SearchLight.query(sql)

2016-12-22T12:18:53.091 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles" LIMIT 1

  0.000637 seconds (16 allocations: 576 bytes)
1×7 DataFrames.DataFrame
│ Row │ articles_id │ articles_title                                     │ articles_summary                                                                          │
├─────┼─────────────┼────────────────────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────┤
│ 1   │ 4           │ "Possimus sit cum nesciunt doloribus dignissimos." │ "Similique.
Ut debitis qui perferendis.
Voluptatem qui recusandae ut itaque voluptas.
Sunt." │

│ Row │ articles_content                                                                                                                                                                                                                            │ articles_updated_at       │ articles_published_at │
├─────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼───────────────────────────┼───────────────────────┤
│ 1   │ "Hic. Est aut officia perspiciatis. Et non est dolor autem..
Aliquid dolores quo aut. Aperiam explicabo..
Itaque molestias facere. Aliquam quam est commodi quod ut. Recusandae consequatur voluptatem. Dolorem qui consectetur dicta modi.." │ "2016-09-27 07:49:59.098" │ NA                    │

│ Row │ articles_slug                                     │
├─────┼───────────────────────────────────────────────────┤
│ 1   │ "possimus-sit-cum-nesciunt-doloribus-dignissimos" │

julia> objects = SearchLight.to_models(Article, df)
1-element Array{App.Article,1}:

App.Article
+==============+=============================================================+
|          key |                                                       value |
+==============+=============================================================+
|              | Hic. Est aut officia perspiciatis. Et non est dolor autem.. |
|      content |                 Aliquid dolores quo aut. Aperiam explica... |
+--------------+-------------------------------------------------------------+
|           id |                                          Nullable{Int32}(4) |
+--------------+-------------------------------------------------------------+
| published_at |                                        Nullable{DateTime}() |
+--------------+-------------------------------------------------------------+
|         slug |             possimus-sit-cum-nesciunt-doloribus-dignissimos |
+--------------+-------------------------------------------------------------+
|              |                                                  Similique. |
|              |                                 Ut debitis qui perferendis. |
|              |               Voluptatem qui recusandae ut itaque voluptas. |
|      summary |                                                       Sunt. |
+--------------+-------------------------------------------------------------+
|        title |            Possimus sit cum nesciunt doloribus dignissimos. |
+--------------+-------------------------------------------------------------+
|   updated_at |                                     2016-09-27T07:49:59.098 |
+--------------+-------------------------------------------------------------+
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L1308-L1367' class='documenter-source'>source</a><br>

<a id='SearchLight.set_relation' href='#SearchLight.set_relation'>#</a>
**`SearchLight.set_relation`** &mdash; *Function*.



```
set_relation{T<:AbstractModel}(r::SQLRelation, related_model::Type{T}, related_model_df::DataFrames.DataFrame) :: SQLRelation
```

Sets relation data for one to many relations.


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L1401-L1405' class='documenter-source'>source</a><br>

<a id='SearchLight.to_model' href='#SearchLight.to_model'>#</a>
**`SearchLight.to_model`** &mdash; *Function*.



```
to_model{T<:AbstractModel}(m::Type{T}, row::DataFrames.DataFrameRow)
```

Converts a DataFrame row to a SearchLight model instance.

**Examples**

```julia
julia> sql = SearchLight.to_find_sql(Article, SQLQuery(limit = 1))
"SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles" LIMIT 1"

julia> df = SearchLight.query(sql)

2016-12-22T13:25:47.34 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles" LIMIT 1

  0.002099 seconds (1.23 k allocations: 52.688 KB)
1×7 DataFrames.DataFrame
│ Row │ articles_id │ articles_title                                     │ articles_summary                                                                          │
├─────┼─────────────┼────────────────────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────┤
│ 1   │ 4           │ "Possimus sit cum nesciunt doloribus dignissimos." │ "Similique.
Ut debitis qui perferendis.
Voluptatem qui recusandae ut itaque voluptas.
Sunt." │

│ Row │ articles_content                                                                                                                                                                                                                            │ articles_updated_at       │ articles_published_at │
├─────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼───────────────────────────┼───────────────────────┤
│ 1   │ "Hic. Est aut officia perspiciatis. Et non est dolor autem..
Aliquid dolores quo aut. Aperiam explicabo..
Itaque molestias facere. Aliquam quam est commodi quod ut. Recusandae consequatur voluptatem. Dolorem qui consectetur dicta modi.." │ "2016-09-27 07:49:59.098" │ NA                    │

│ Row │ articles_slug                                     │
├─────┼───────────────────────────────────────────────────┤
│ 1   │ "possimus-sit-cum-nesciunt-doloribus-dignissimos" │

julia> dfr = DataFrames.DataFrameRow(df, 1)
DataFrameRow (row 1)
articles_id            4
articles_title         Possimus sit cum nesciunt doloribus dignissimos.
articles_summary       Similique.
Ut debitis qui perferendis.
Voluptatem qui recusandae ut itaque voluptas.
Sunt.
articles_content       Hic. Est aut officia perspiciatis. Et non est dolor autem..
Aliquid dolores quo aut. Aperiam explicabo..
Itaque molestias facere. Aliquam quam est commodi quod ut. Recusandae consequatur voluptatem. Dolorem qui consectetur dicta modi..
articles_updated_at    2016-09-27 07:49:59.098
articles_published_at  NA
articles_slug          possimus-sit-cum-nesciunt-doloribus-dignissimos


julia> SearchLight.to_model(Article, dfr)

App.Article
+==============+=============================================================+
|          key |                                                       value |
+==============+=============================================================+
|              | Hic. Est aut officia perspiciatis. Et non est dolor autem.. |
|      content |                 Aliquid dolores quo aut. Aperiam explica... |
+--------------+-------------------------------------------------------------+
|           id |                                          Nullable{Int32}(4) |
+--------------+-------------------------------------------------------------+
| published_at |                                        Nullable{DateTime}() |
+--------------+-------------------------------------------------------------+
|         slug |             possimus-sit-cum-nesciunt-doloribus-dignissimos |
+--------------+-------------------------------------------------------------+
|              |                                                  Similique. |
|              |                                 Ut debitis qui perferendis. |
|              |               Voluptatem qui recusandae ut itaque voluptas. |
|      summary |                                                       Sunt. |
+--------------+-------------------------------------------------------------+
|        title |            Possimus sit cum nesciunt doloribus dignissimos. |
+--------------+-------------------------------------------------------------+
|   updated_at |                                     2016-09-27T07:49:59.098 |
+--------------+-------------------------------------------------------------+
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L1421-L1495' class='documenter-source'>source</a><br>


```
to_model{T<:AbstractModel}(m::Type{T}, df::DataFrames.DataFrame; row_index = 1) :: Nullable{T}
```

Attempts to extract row at `row_index` from `df` and convert it to an instance of `T`.

**Examples**

```julia
julia> df = SearchLight.query(SearchLight.to_find_sql(Article, SQLQuery(where = [SQLWhereExpression("title LIKE ?", "%a%")], limit = 1)))

2016-12-22T14:00:34.063 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles" WHERE title LIKE '%a%' LIMIT 1

  0.000846 seconds (16 allocations: 576 bytes)

1×7 DataFrames.DataFrame
...

julia> SearchLight.to_model(Article, df)
Nullable{App.Article}(
App.Article
+==============+======================================================================================+
|          key |                                                                                value |
+==============+======================================================================================+
|              | Ducimus fuga sit magni. Non labore facilis dolore. Nisi dignissimos. Voluptas quis.. |
|      content |                                                                   Ullam sequi dol... |
+--------------+--------------------------------------------------------------------------------------+
|           id |                                                                   Nullable{Int32}(5) |
+--------------+--------------------------------------------------------------------------------------+
| published_at |                                                                 Nullable{DateTime}() |
+--------------+--------------------------------------------------------------------------------------+
|         slug |                                                    voluptas-ea-incidunt-et-provident |
+--------------+--------------------------------------------------------------------------------------+
|              |                                                                    Animi ducimus in. |
|              |                               Voluptatem ipsum doloribus perspiciatis consequatur a. |
|      summary |                                                       Vel quibusdam quas veritati... |
+--------------+--------------------------------------------------------------------------------------+
|        title |                                                   Voluptas ea incidunt et provident. |
+--------------+--------------------------------------------------------------------------------------+
|   updated_at |                                                              2016-09-27T07:49:59.129 |
+--------------+--------------------------------------------------------------------------------------+
)

julia> df = SearchLight.query(SearchLight.to_find_sql(Article, SQLQuery(where = [SQLWhereExpression("title LIKE ?", "%agggzgguuyyyo79%")], limit = 1)))

2016-12-22T14:02:01.938 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles" WHERE title LIKE '%agggzgguuyyyo79%' LIMIT 1

  0.000648 seconds (16 allocations: 576 bytes)

0×7 DataFrames.DataFrame

julia> SearchLight.to_model(Article, df)
Nullable{App.Article}()
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L1622-L1674' class='documenter-source'>source</a><br>

<a id='SearchLight.to_model!!' href='#SearchLight.to_model!!'>#</a>
**`SearchLight.to_model!!`** &mdash; *Function*.



```
to_model!!{T<:AbstractModel}(m::Type{T}, df::DataFrames.DataFrame; row_index = 1) :: T
```

Gets the DataFrameRow instance at `row_index` and converts it into an instance of model `T`.

**Examples**

```julia
julia> df = SearchLight.query(SearchLight.to_find_sql(Article, SQLQuery(where = [SQLWhereExpression("id = 11")])))

2016-12-22T13:47:06.929 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles" WHERE id = 11

  0.000649 seconds (16 allocations: 576 bytes)

1×7 DataFrames.DataFrame
...

julia> SearchLight.to_model!!(Article, df)

App.Article
+==============+=========================================================================================================+
|          key |                                                                                                   value |
+==============+=========================================================================================================+
|      content | Porro est eaque impedit sint quos. Provident neque numquam dignissimos. Et aliquid natus libero ut. ... |
+--------------+---------------------------------------------------------------------------------------------------------+
|           id |                                                                                     Nullable{Int32}(11) |
+--------------+---------------------------------------------------------------------------------------------------------+
| published_at |                                                                                    Nullable{DateTime}() |
+--------------+---------------------------------------------------------------------------------------------------------+
|         slug |                                                                                 facere-hic-ut-libero-et |
+--------------+---------------------------------------------------------------------------------------------------------+
|              |                                                                              Optio quam necessitatibus. |
|              |                                                                      Praesentium dolorem et cupiditate. |
|              |                                                                                              Omnis vel. |
|      summary |                                                                                             Voluptatem. |
+--------------+---------------------------------------------------------------------------------------------------------+
|        title |                                                                                Facere hic ut libero et. |
+--------------+---------------------------------------------------------------------------------------------------------+
|   updated_at |                                                                                 2016-09-27T07:49:59.323 |
+--------------+---------------------------------------------------------------------------------------------------------+

julia> df = SearchLight.query(SearchLight.to_find_sql(Article, SQLQuery(where = [SQLWhereExpression("title = '--- this article does not exist --'")])))

2016-12-22T13:48:56.781 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles" WHERE title = '--- this article does not exist --'

  0.000724 seconds (16 allocations: 576 bytes)

0×7 DataFrames.DataFrame

julia> SearchLight.to_model!!(Article, df)
------ BoundsError ---------------------
...
BoundsError: attempt to access 0-element BitArray{1} at index [1]
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L1561-L1614' class='documenter-source'>source</a><br>

<a id='SearchLight.to_select_part' href='#SearchLight.to_select_part'>#</a>
**`SearchLight.to_select_part`** &mdash; *Function*.



```
to_select_part{T<:AbstractModel}(m::Type{T}, cols::Vector{SQLColumn}[, joins = SQLJoin[] ]) :: String
to_select_part{T<:AbstractModel}(m::Type{T}, c::SQLColumn) :: String
to_select_part{T<:AbstractModel}(m::Type{T}, c::String) :: String
to_select_part{T<:AbstractModel}(m::Type{T}) :: String
```

Generates the SELECT part of the SQL query.

**Examples**

```julia
julia> SearchLight.to_select_part(Article)
"SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug""

julia> SearchLight.to_select_part(Article, "id")
"SELECT articles.id AS articles_id"

julia> SearchLight.to_select_part(Article, SQLColumn(:slug))
"SELECT articles.slug AS articles_slug"

julia> SearchLight.to_select_part(Article, SQLColumn[:id, :slug, :title])
"SELECT articles.id AS articles_id, articles.slug AS articles_slug, articles.title AS articles_title"
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L1690-L1712' class='documenter-source'>source</a><br>

<a id='SearchLight.to_from_part' href='#SearchLight.to_from_part'>#</a>
**`SearchLight.to_from_part`** &mdash; *Function*.



```
to_from_part{T<:AbstractModel}(m::Type{T})
```

Generates the FROM part of the SQL query.

**Examples**

```julia
julia> SearchLight.to_from_part(Article)
"FROM "articles""
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L1727-L1737' class='documenter-source'>source</a><br>

<a id='SearchLight.to_where_part' href='#SearchLight.to_where_part'>#</a>
**`SearchLight.to_where_part`** &mdash; *Function*.



```
to_where_part{T<:AbstractModel}(m::Type{T}, w::Vector{SQLWhereEntity}) :: String
to_where_part(w::Vector{SQLWhereEntity}) :: String
```

Generates the WHERE part of the SQL query.

**Examples**

```julia
julia> SearchLight.required_scopes(Article)
1-element Array{Union{SearchLight.SQLWhere,SearchLight.SQLWhereExpression},1}:

SearchLight.SQLWhereExpression
+================+====================+
|            key |              value |
+================+====================+
|      condition |                AND |
+----------------+--------------------+
| sql_expression | id BETWEEN ? AND ? |
+----------------+--------------------+
|         values |                1,2 |
+----------------+--------------------+

julia> SearchLight.to_where_part(Article)
"WHERE id BETWEEN 1 AND 2" # required scope automatically applied

julia> SearchLight.to_where_part(Article, SQLWhereEntity[SQLWhere(:id, 2)])
"WHERE ("id" = 2) AND id BETWEEN 1 AND 2"

julia> SearchLight.scopes(Article)
Dict{Symbol,Array{Union{SearchLight.SQLWhere,SearchLight.SQLWhereExpression},1}} with 2 entries:
  :own      => Union{SearchLight.SQLWhere,SearchLight.SQLWhereExpression}[…
  :required => Union{SearchLight.SQLWhere,SearchLight.SQLWhereExpression}[…

julia> SearchLight.to_where_part(Article, SQLWhereEntity[SQLWhere(:id, 2)], [:own])
"WHERE ("id" = 2) AND id BETWEEN 1 AND 2 AND ("user_id" = 1)"
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L1743-L1779' class='documenter-source'>source</a><br>

<a id='SearchLight.required_scopes' href='#SearchLight.required_scopes'>#</a>
**`SearchLight.required_scopes`** &mdash; *Function*.



```
required_scopes{T<:AbstractModel}(m::Type{T}) :: Vector{SQLWhereEntity}
```

Returns the Vector containing the required scopes defined on the model `m`. The required scopes are defined under the `:required` key and are automatically applied to all the SQL queries.

**Examples**

```julia
julia> SearchLight.required_scopes(Article)
1-element Array{Union{SearchLight.SQLWhere,SearchLight.SQLWhereExpression},1}:

SearchLight.SQLWhereExpression
+================+====================+
|            key |              value |
+================+====================+
|      condition |                AND |
+----------------+--------------------+
| sql_expression | id BETWEEN ? AND ? |
+----------------+--------------------+
|         values |                1,2 |
+----------------+--------------------+
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L1788-L1810' class='documenter-source'>source</a><br>

<a id='SearchLight.scopes' href='#SearchLight.scopes'>#</a>
**`SearchLight.scopes`** &mdash; *Function*.



```
scopes{T<:AbstractModel}(m::Type{T}) :: Dict{Symbol,Vector{SQLWhereEntity}}
```

Returns a `Dict` containing the names of all the scopes defined on the model `m` as keys, and the corresponding `Vectors` of `SQLWhereEntity` that make up the actual scopes. Includes the `:required` scope if defined.

**Examples**

```julia
julia> SearchLight.scopes(Article)
Dict{Symbol,Array{Union{SearchLight.SQLWhere,SearchLight.SQLWhereExpression},1}} with 2 entries:
  :own      => Union{SearchLight.SQLWhere,SearchLight.SQLWhereExpression}[…
  :required => Union{SearchLight.SQLWhere,SearchLight.SQLWhereExpression}[…

julia> SearchLight.scopes(Article)[:required]
1-element Array{Union{SearchLight.SQLWhere,SearchLight.SQLWhereExpression},1}:

SearchLight.SQLWhereExpression
+================+====================+
|            key |              value |
+================+====================+
|      condition |                AND |
+----------------+--------------------+
| sql_expression | id BETWEEN ? AND ? |
+----------------+--------------------+
|         values |                1,2 |
+----------------+--------------------+
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L1816-L1843' class='documenter-source'>source</a><br>

<a id='SearchLight.scopes_names' href='#SearchLight.scopes_names'>#</a>
**`SearchLight.scopes_names`** &mdash; *Function*.



```
scopes_names{T<:AbstractModel}(m::Type{T}) :: Vector{Symbol}
```

Returns the names of all the scopes defined on the model `m`, as a `Vector` of `Symbol`. Includes the `:required` scope if defined.

**Examples**

```julia
julia> SearchLight.scopes_names(Article)
2-element Array{Symbol,1}:
 :own
 :required
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L1849-L1862' class='documenter-source'>source</a><br>

<a id='SearchLight.to_order_part' href='#SearchLight.to_order_part'>#</a>
**`SearchLight.to_order_part`** &mdash; *Function*.



```
to_order_part{T<:AbstractModel}(m::Type{T}, o::Vector{SQLOrder}) :: String
```

Generates the ORDER part of the SQL query.

**Examples**

```julia
julia> SearchLight.to_order_part(Article, SQLOrder[:id, :title])
"ORDER BY articles.id ASC, articles.title ASC"
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L1868-L1878' class='documenter-source'>source</a><br>

<a id='SearchLight.to_group_part' href='#SearchLight.to_group_part'>#</a>
**`SearchLight.to_group_part`** &mdash; *Function*.



```
to_group_part(g::Vector{SQLColumn}) :: String
```

Generates the GROUP part of the SQL query.

**Examples**

```julia
julia> SearchLight.to_group_part(SQLColumn[:id, :title])
" GROUP BY "id", "title""
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L1884-L1894' class='documenter-source'>source</a><br>

<a id='SearchLight.to_limit_part' href='#SearchLight.to_limit_part'>#</a>
**`SearchLight.to_limit_part`** &mdash; *Function*.



```
to_limit_part(l::SQLLimit) :: String
to_limit_part(l::Int) :: String
```

Generates the LIMIT part of the SQL query.

**Examples**

```julia
julia> SearchLight.to_limit_part(SQLLimit(1))
"LIMIT 1"

julia> SearchLight.to_limit_part(1)
"LIMIT 1"
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L1900-L1914' class='documenter-source'>source</a><br>

<a id='SearchLight.to_offset_part' href='#SearchLight.to_offset_part'>#</a>
**`SearchLight.to_offset_part`** &mdash; *Function*.



```
to_offset_part(o::Int) :: String
```

Generates the OFFSET part of the SQL query.

**Examples**

```julia
julia> SearchLight.to_offset_part(10)
"OFFSET 10"
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L1923-L1933' class='documenter-source'>source</a><br>

<a id='SearchLight.to_having_part' href='#SearchLight.to_having_part'>#</a>
**`SearchLight.to_having_part`** &mdash; *Function*.



```
to_having_part(h::Vector{SQLHaving}) :: String
```

Generates the HAVING part of the SQL query.

**Examples**

```julia
julia> SearchLight.to_having_part(SQLHaving[SQLWhere(:aggregated_amount, 200, ">=")])
"HAVING ("aggregated_amount" >= 200)"
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L1939-L1949' class='documenter-source'>source</a><br>

<a id='SearchLight.to_join_part' href='#SearchLight.to_join_part'>#</a>
**`SearchLight.to_join_part`** &mdash; *Function*.



```
to_join_part{T<:AbstractModel}(m::Type{T}[, joins = SQLJoin[] ]) :: String
```

Generates the JOIN part of the SQL query.

**Examples**

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
|      where |                                                +========... |
+------------+-------------------------------------------------------------+

julia> SearchLight.to_join_part(User, [j])
"  INNER  JOIN "roles"  ON "users"."role_id" = "roles"."id"  WHERE role_id > 10"
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L1955-L2002' class='documenter-source'>source</a><br>

<a id='SearchLight.relations' href='#SearchLight.relations'>#</a>
**`SearchLight.relations`** &mdash; *Function*.



```
relations{T<:AbstractModel}(m::Type{T}) :: Vector{Tuple{SQLRelation,Symbol}}
```

Returns the vector of relations for the given model type.

**Examples**

```julia
julia> SearchLight.relations(User)
1-element Array{Tuple{SearchLight.SQLRelation,Symbol},1}:
 (
SearchLight.SQLRelation{App.Role}
+============+=================================================================================+
|        key |                                                                           value |
+============+=================================================================================+
|       data | Nullable{Union{Array{SearchLight.AbstractModel,1},SearchLight.AbstractModel}}() |
+------------+---------------------------------------------------------------------------------+
|  eagerness |                                                                            auto |
+------------+---------------------------------------------------------------------------------+
|       join |                   Nullable{SearchLight.SQLJoin{T<:SearchLight.AbstractModel}}() |
+------------+---------------------------------------------------------------------------------+
| model_name |                                                                        App.Role |
+------------+---------------------------------------------------------------------------------+
|   required |                                                                           false |
+------------+---------------------------------------------------------------------------------+
,:belongs_to)
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L2008-L2034' class='documenter-source'>source</a><br>

<a id='SearchLight.relation' href='#SearchLight.relation'>#</a>
**`SearchLight.relation`** &mdash; *Function*.



```
relation{T<:AbstractModel,R<:AbstractModel}(m::T, model_name::Type{R}, relation_type::Symbol) :: Nullable{SQLRelation{R}}
```

Gets the relation instance of `relation_type` for the model instance `m` and `model_name`.

**Examples**

```julia
julia> u = SearchLight.find_one!!(User, 1)

2016-12-23T10:47:33.021 - info: SQL QUERY: SELECT "users"."id" AS "users_id", "users"."name" AS "users_name", "users"."email" AS "users_email", "users"."password" AS "users_password", "users"."role_id" AS "users_role_id", "users"."updated_at" AS "users_updated_at" FROM "users" WHERE ("id" = 1) ORDER BY users.id ASC LIMIT 1

  0.002944 seconds (1.23 k allocations: 52.641 KB)

2016-12-23T10:47:36.711 - info: SQL QUERY: SELECT "roles"."id" AS "roles_id", "roles"."name" AS "roles_name" FROM "roles" WHERE (roles.id = 2) LIMIT 1

  0.000711 seconds (13 allocations: 432 bytes)

App.User
+============+==================================================================+
|        key |                                                            value |
+============+==================================================================+
|      email |                                                 e@essenciary.com |
+------------+------------------------------------------------------------------+
|         id |                                               Nullable{Int32}(1) |
+------------+------------------------------------------------------------------+
|       name |                                                  Adrian Salceanu |
+------------+------------------------------------------------------------------+
|   password | 9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08 |
+------------+------------------------------------------------------------------+
|    role_id |                                               Nullable{Int32}(2) |
+------------+------------------------------------------------------------------+
| updated_at |                                              2016-08-25T20:05:24 |
+------------+------------------------------------------------------------------+


julia> SearchLight.relations(User)
1-element Array{Tuple{SearchLight.SQLRelation,Symbol},1}:
 (
SearchLight.SQLRelation{App.Role}
+============+=======================================================================+
|        key |                                                                 value |
+============+=======================================================================+
|       data | Nullable{SearchLight.SQLRelationData{T<:SearchLight.AbstractModel}}() |
+------------+-----------------------------------------------------------------------+
|  eagerness |                                                                  auto |
+------------+-----------------------------------------------------------------------+
|       join |         Nullable{SearchLight.SQLJoin{T<:SearchLight.AbstractModel}}() |
+------------+-----------------------------------------------------------------------+
| model_name |                                                              App.Role |
+------------+-----------------------------------------------------------------------+
|   required |                                                                 false |
+------------+-----------------------------------------------------------------------+
,:belongs_to)

julia> SearchLight.relation(u, Role, :belongs_to)
Nullable{SearchLight.SQLRelation{App.Role}}(
SearchLight.SQLRelation{App.Role}
+============+======================================================================+
|        key |                                                                value |
+============+======================================================================+
|            | Nullable{SearchLight.SQLRelationData{T<:SearchLight.AbstractModel}}( |
|       data |                                   SearchLight.SQLRelationData{App... |
+------------+----------------------------------------------------------------------+
|  eagerness |                                                                 auto |
+------------+----------------------------------------------------------------------+
|       join |        Nullable{SearchLight.SQLJoin{T<:SearchLight.AbstractModel}}() |
+------------+----------------------------------------------------------------------+
| model_name |                                                             App.Role |
+------------+----------------------------------------------------------------------+
|   required |                                                                false |
+------------+----------------------------------------------------------------------+
)
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L2055-L2128' class='documenter-source'>source</a><br>

<a id='SearchLight.relation_data' href='#SearchLight.relation_data'>#</a>
**`SearchLight.relation_data`** &mdash; *Function*.



```
relation_data{T<:AbstractModel,R<:AbstractModel}(m::T, model_name::Type{R}, relation_type::Symbol) :: Nullable{SQLRelationData{R}}
```

Retrieves the data (model object or vector of model objects) associated by the relation.

**Examples**

```julia
julia> u = SearchLight.find_one!!(User, 1)

2016-12-22T19:01:24.483 - info: SQL QUERY: SELECT "users"."id" AS "users_id", "users"."name" AS "users_name", "users"."email" AS "users_email", "users"."password" AS "users_password", "users"."role_id" AS "users_role_id", "users"."updated_at" AS "users_updated_at" FROM "users" WHERE ("id" = 1) ORDER BY users.id ASC LIMIT 1

  0.002004 seconds (1.23 k allocations: 52.641 KB)

2016-12-22T19:01:28.214 - info: SQL QUERY: SELECT "roles"."id" AS "roles_id", "roles"."name" AS "roles_name" FROM "roles" WHERE (roles.id = 2) LIMIT 1

  0.000760 seconds (13 allocations: 432 bytes)

App.User
+============+==================================================================+
|        key |                                                            value |
+============+==================================================================+
|      email |                                                genie@example.com |
+------------+------------------------------------------------------------------+
|         id |                                               Nullable{Int32}(1) |
+------------+------------------------------------------------------------------+
|       name |                                                  Adrian Salceanu |
+------------+------------------------------------------------------------------+
|   password | 9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08 |
+------------+------------------------------------------------------------------+
|    role_id |                                               Nullable{Int32}(2) |
+------------+------------------------------------------------------------------+
| updated_at |                                              2016-08-25T20:05:24 |
+------------+------------------------------------------------------------------+


julia> SearchLight.relation_data(u, Role, :belongs_to)
Nullable{SearchLight.SQLRelationData{App.Role}}(
SearchLight.SQLRelationData{App.Role}
+============+===============================+
|        key |                         value |
+============+===============================+
|            |                     App.Role[ |
|            |                      App.Role |
|            | +======+====================+ |
|            | |  key |              value | |
| collection |      +======+=============... |
+------------+-------------------------------+
)
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L2148-L2197' class='documenter-source'>source</a><br>

<a id='SearchLight.relation_data!!' href='#SearchLight.relation_data!!'>#</a>
**`SearchLight.relation_data!!`** &mdash; *Function*.



```
relation_data!!{T<:AbstractModel,R<:AbstractModel}(m::T, model_name::Type{R}, relation_type::Symbol) :: SQLRelationData{R}
```

Retrieves the data (model object or vector of model objects) associated by the relation. Similar to `relation_data` except if the data is null, throws error.

**Examples**

```julia
julia> u = SearchLight.find_one!!(User, 1)

2016-12-22T19:01:24.483 - info: SQL QUERY: SELECT "users"."id" AS "users_id", "users"."name" AS "users_name", "users"."email" AS "users_email", "users"."password" AS "users_password", "users"."role_id" AS "users_role_id", "users"."updated_at" AS "users_updated_at" FROM "users" WHERE ("id" = 1) ORDER BY users.id ASC LIMIT 1

  0.002004 seconds (1.23 k allocations: 52.641 KB)

2016-12-22T19:01:28.214 - info: SQL QUERY: SELECT "roles"."id" AS "roles_id", "roles"."name" AS "roles_name" FROM "roles" WHERE (roles.id = 2) LIMIT 1

  0.000760 seconds (13 allocations: 432 bytes)

App.User
+============+==================================================================+
|        key |                                                            value |
+============+==================================================================+
|      email |                                                genie@example.com |
+------------+------------------------------------------------------------------+
|         id |                                               Nullable{Int32}(1) |
+------------+------------------------------------------------------------------+
|       name |                                                  Adrian Salceanu |
+------------+------------------------------------------------------------------+
|   password | 9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08 |
+------------+------------------------------------------------------------------+
|    role_id |                                               Nullable{Int32}(2) |
+------------+------------------------------------------------------------------+
| updated_at |                                              2016-08-25T20:05:24 |
+------------+------------------------------------------------------------------+

julia> SearchLight.relation_data!!(u, Role, :belongs_to)

SearchLight.SQLRelationData{App.Role}
+============+===============================+
|        key |                         value |
+============+===============================+
|            |                     App.Role[ |
|            |                      App.Role |
|            | +======+====================+ |
|            | |  key |              value | |
| collection |      +======+=============... |
+------------+-------------------------------+
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L2208-L2255' class='documenter-source'>source</a><br>

<a id='SearchLight.relation_collection!!' href='#SearchLight.relation_collection!!'>#</a>
**`SearchLight.relation_collection!!`** &mdash; *Function*.



```
relation_collection!!{T<:AbstractModel,R<:AbstractModel}(m::T, model_name::Type{R}, relation_type::Symbol) :: Vector{R}
```

Returns the collection (vector) containing the data associated through the relation.

**Examples**

```julia
julia> SearchLight.relation_collection!!(SearchLight.find_one!!(User, 1), Role, :belongs_to)

2016-12-23T12:21:14.519 - info: SQL QUERY: SELECT "users"."id" AS "users_id", "users"."name" AS "users_name", "users"."email" AS "users_email", "users"."password" AS "users_password", "users"."role_id" AS "users_role_id", "users"."updated_at" AS "users_updated_at" FROM "users" WHERE ("id" = 1) ORDER BY users.id ASC LIMIT 1

  0.001603 seconds (15 allocations: 528 bytes)

2016-12-23T12:21:14.548 - info: SQL QUERY: SELECT "roles"."id" AS "roles_id", "roles"."name" AS "roles_name" FROM "roles" WHERE (roles.id = 2) LIMIT 1

  0.000593 seconds (13 allocations: 432 bytes)
1-element Array{App.Role,1}:

App.Role
+======+====================+
|  key |              value |
+======+====================+
|   id | Nullable{Int32}(2) |
+------+--------------------+
| name |              admin |
+------+--------------------+
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L2261-L2288' class='documenter-source'>source</a><br>

<a id='SearchLight.relation_object!!' href='#SearchLight.relation_object!!'>#</a>
**`SearchLight.relation_object!!`** &mdash; *Function*.



```
relation_object!!{T<:AbstractModel,R<:AbstractModel}(m::T, model_name::Type{R}, relation_type::Symbol; idx = 1) :: R
```

Returns the model object at `idx` from the collection defined by the associated relation.

**Examples**

```julia
julia> SearchLight.relation_object!!(SearchLight.find_one!!(User, 1), Role, :belongs_to)

2016-12-23T12:22:44.321 - info: SQL QUERY: SELECT "users"."id" AS "users_id", "users"."name" AS "users_name", "users"."email" AS "users_email", "users"."password" AS "users_password", "users"."role_id" AS "users_role_id", "users"."updated_at" AS "users_updated_at" FROM "users" WHERE ("id" = 1) ORDER BY users.id ASC LIMIT 1

  0.000666 seconds (15 allocations: 528 bytes)

2016-12-23T12:22:44.328 - info: SQL QUERY: SELECT "roles"."id" AS "roles_id", "roles"."name" AS "roles_name" FROM "roles" WHERE (roles.id = 2) LIMIT 1

  0.000477 seconds (13 allocations: 432 bytes)

App.Role
+======+====================+
|  key |              value |
+======+====================+
|   id | Nullable{Int32}(2) |
+------+--------------------+
| name |              admin |
+------+--------------------+
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L2294-L2320' class='documenter-source'>source</a><br>

<a id='SearchLight.get_relation_data' href='#SearchLight.get_relation_data'>#</a>
**`SearchLight.get_relation_data`** &mdash; *Function*.



```
get_relation_data{T<:AbstractModel}{R<:AbstractModel}(m::T, rel::SQLRelation{R}, relation_type::Symbol) :: Nullable{SQLRelationData{R}}
get_relation_data{T<:AbstractModel,R<:AbstractModel}(m::T, relation_info::Tuple{SQLRelation,Symbol}) :: Nullable{SQLRelationData{R}}
```

Extracts the data (instantiates the models) associated by the relation, performing the corresponding SQL queries.

**Examples**

```julia
julia> SearchLight.relations(User)
1-element Array{Tuple{SearchLight.SQLRelation,Symbol},1}:
 (
SearchLight.SQLRelation{App.Role}
+============+=======================================================================+
|        key |                                                                 value |
+============+=======================================================================+
|       data | Nullable{SearchLight.SQLRelationData{T<:SearchLight.AbstractModel}}() |
+------------+-----------------------------------------------------------------------+
|  eagerness |                                                                  auto |
+------------+-----------------------------------------------------------------------+
|       join |         Nullable{SearchLight.SQLJoin{T<:SearchLight.AbstractModel}}() |
+------------+-----------------------------------------------------------------------+
| model_name |                                                              App.Role |
+------------+-----------------------------------------------------------------------+
|   required |                                                                 false |
+------------+-----------------------------------------------------------------------+
,:belongs_to)

julia> SearchLight.get_relation_data(SearchLight.find_one!!(User, 1), SearchLight.relations(User)[1][1], :belongs_to)

2016-12-23T12:24:09.542 - info: SQL QUERY: SELECT "users"."id" AS "users_id", "users"."name" AS "users_name", "users"."email" AS "users_email", "users"."password" AS "users_password", "users"."role_id" AS "users_role_id", "users"."updated_at" AS "users_updated_at" FROM "users" WHERE ("id" = 1) ORDER BY users.id ASC LIMIT 1

  0.000608 seconds (15 allocations: 528 bytes)

2016-12-23T12:24:09.549 - info: SQL QUERY: SELECT "roles"."id" AS "roles_id", "roles"."name" AS "roles_name" FROM "roles" WHERE (roles.id = 2) LIMIT 1

  0.000519 seconds (13 allocations: 432 bytes)

2016-12-23T12:24:09.557 - info: SQL QUERY: SELECT "roles"."id" AS "roles_id", "roles"."name" AS "roles_name" FROM "roles" WHERE (roles.id = 2) LIMIT 1

  0.000658 seconds (13 allocations: 432 bytes)
Nullable{SearchLight.SQLRelationData{App.Role}}(
SearchLight.SQLRelationData{App.Role}
+============+===============================+
|        key |                         value |
+============+===============================+
|            |                     App.Role[ |
|            |                      App.Role |
|            | +======+====================+ |
|            | |  key |              value | |
| collection |      +======+=============... |
+------------+-------------------------------+
)

###

julia> rels = SearchLight.relations(User)
1-element Array{Tuple{SearchLight.SQLRelation,Symbol},1}:
 (
SearchLight.SQLRelation{App.Role}
+============+=======================================================================+
|        key |                                                                 value |
+============+=======================================================================+
|       data | Nullable{SearchLight.SQLRelationData{T<:SearchLight.AbstractModel}}() |
+------------+-----------------------------------------------------------------------+
|  eagerness |                                                                  auto |
+------------+-----------------------------------------------------------------------+
|       join |         Nullable{SearchLight.SQLJoin{T<:SearchLight.AbstractModel}}() |
+------------+-----------------------------------------------------------------------+
| model_name |                                                              App.Role |
+------------+-----------------------------------------------------------------------+
|   required |                                                                 false |
+------------+-----------------------------------------------------------------------+
,:belongs_to)

julia> SearchLight.get_relation_data(SearchLight.find_one!!(User, 1), rels[1])

2016-12-23T12:29:25.033 - info: SQL QUERY: SELECT "users"."id" AS "users_id", "users"."name" AS "users_name", "users"."email" AS "users_email", "users"."password" AS "users_password", "users"."role_id" AS "users_role_id", "users"."updated_at" AS "users_updated_at" FROM "users" WHERE ("id" = 1) ORDER BY users.id ASC LIMIT 1

  0.001999 seconds (1.23 k allocations: 52.641 KB)

2016-12-23T12:29:28.681 - info: SQL QUERY: SELECT "roles"."id" AS "roles_id", "roles"."name" AS "roles_name" FROM "roles" WHERE (roles.id = 2) LIMIT 1

  0.000733 seconds (13 allocations: 432 bytes)

2016-12-23T12:29:28.874 - info: SQL QUERY: SELECT "roles"."id" AS "roles_id", "roles"."name" AS "roles_name" FROM "roles" WHERE (roles.id = 2) LIMIT 1

  0.000567 seconds (13 allocations: 432 bytes)
Nullable{SearchLight.SQLRelationData{App.Role}}(
SearchLight.SQLRelationData{App.Role}
+============+===============================+
|        key |                         value |
+============+===============================+
|            |                     App.Role[ |
|            |                      App.Role |
|            | +======+====================+ |
|            | |  key |              value | |
| collection |      +======+=============... |
+------------+-------------------------------+
)
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L2326-L2426' class='documenter-source'>source</a><br>

<a id='SearchLight.relations_tables_names' href='#SearchLight.relations_tables_names'>#</a>
**`SearchLight.relations_tables_names`** &mdash; *Function*.



```
relations_tables_names{T<:AbstractModel}(m::Type{T}) :: Vector{String}
```

Returns a vector of strings containing the names of the related SQL database tables.

**Examples**

```julia
julia> SearchLight.relations_tables_names(User)
1-element Array{String,1}:
 "roles"
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L2458-L2469' class='documenter-source'>source</a><br>

<a id='SearchLight.columns_names_by_table' href='#SearchLight.columns_names_by_table'>#</a>
**`SearchLight.columns_names_by_table`** &mdash; *Function*.



```
columns_names_by_table(tables_names::Vector{String}, df::DataFrame) :: Dict{String,Vector{Symbol}}
```

Returns the names of the columns from `df` grouped by table name – as a `Dict` that has as keys the names of the tables from `tables_names` and as values vectors of symbols representing the names of the columns from `df`.

**Examples**

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


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L2482-L2506' class='documenter-source'>source</a><br>

<a id='SearchLight.dataframes_by_table' href='#SearchLight.dataframes_by_table'>#</a>
**`SearchLight.dataframes_by_table`** &mdash; *Function*.



```
dataframes_by_table(tables_names::Vector{String}, tables_columns::Dict{String,Vector{Symbol}}, df::DataFrame) :: Dict{String,DataFrame}
```

Breaks a `DataFrame` into multiple dataframes by table names - one `DataFrame` corresponding to the columns of each table. The resulting `DataFrame`s are return as a `Dict` with the keys being the table names.

**Examples**

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


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L2536-L2567' class='documenter-source'>source</a><br>

<a id='SearchLight.relation_to_sql' href='#SearchLight.relation_to_sql'>#</a>
**`SearchLight.relation_to_sql`** &mdash; *Function*.



```
relation_to_sql{T<:AbstractModel}(m::T, rel::Tuple{SQLRelation,Symbol}) :: String
```

Returns the part of the SQL query that corresponds to the SQL JOIN defined by the relationship.

**Examples**

```julia
julia> SearchLight.relation_to_sql(SearchLight.find_one!!(User, 1), SearchLight.relations(User)[1])

2016-12-23T14:52:35.711 - info: SQL QUERY: SELECT "users"."id" AS "users_id", "users"."name" AS "users_name", "users"."email" AS "users_email", "users"."password" AS "users_password", "users"."role_id" AS "users_role_id", "users"."updated_at" AS "users_updated_at", "roles"."id" AS "roles_id", "roles"."name" AS "roles_name" FROM "users" LEFT JOIN "roles" ON "users"."role_id" = "roles"."id" WHERE ("users"."id" = 1) ORDER BY users.id ASC LIMIT 1

  0.000880 seconds (16 allocations: 576 bytes)

2016-12-23T14:52:35.724 - info: SQL QUERY: SELECT "roles"."id" AS "roles_id", "roles"."name" AS "roles_name" FROM "roles" WHERE (roles.id = 2) LIMIT 1

  0.000461 seconds (13 allocations: 432 bytes)
""roles" ON "users"."role_id" = "roles"."id""
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L2584-L2602' class='documenter-source'>source</a><br>

<a id='SearchLight.to_find_sql' href='#SearchLight.to_find_sql'>#</a>
**`SearchLight.to_find_sql`** &mdash; *Function*.



```
to_find_sql{T<:AbstractModel,N<:AbstractModel}(m::Type{T}[, q::SQLQuery[, joins::Vector{SQLJoin{N}}]]) :: String
```

Returns the complete SELECT SQL query corresponding to `m` and `q`.

**Examples**

```julia
julia> SearchLight.to_find_sql(User, SQLQuery())
"SELECT "users"."id" AS "users_id", "users"."name" AS "users_name", "users"."email" AS "users_email", "users"."password" AS "users_password", "users"."role_id" AS "users_role_id", "users"."updated_at" AS "users_updated_at", "roles"."id" AS "roles_id", "roles"."name" AS "roles_name" FROM "users" LEFT JOIN "roles" ON "users"."role_id" = "roles"."id""
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L2608-L2618' class='documenter-source'>source</a><br>

<a id='SearchLight.to_store_sql' href='#SearchLight.to_store_sql'>#</a>
**`SearchLight.to_store_sql`** &mdash; *Function*.



```
to_store_sql{T<:AbstractModel}(m::T; conflict_strategy = :error) :: String
```

Generates the INSERT SQL query.


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L2630-L2634' class='documenter-source'>source</a><br>

<a id='SearchLight.to_sqlinput' href='#SearchLight.to_sqlinput'>#</a>
**`SearchLight.to_sqlinput`** &mdash; *Function*.



```
to_sqlinput{T<:AbstractModel}(m::T, field::Symbol, value) :: SQLInput
```

SQLInput constructor that applies various processing steps to prepare the enclosed value for database persistance (escaping, etc). Applies `on_dehydration` callback if defined.

**Examples**

```julia
julia> SearchLight.to_sqlinput(SearchLight.find_one!!(User, 1), :email, "genie@example.com'; DROP users;")

2016-12-23T15:09:27.166 - info: SQL QUERY: SELECT "users"."id" AS "users_id", "users"."name" AS "users_name", "users"."email" AS "users_email", "users"."password" AS "users_password", "users"."role_id" AS "users_role_id", "users"."updated_at" AS "users_updated_at", "roles"."id" AS "roles_id", "roles"."name" AS "roles_name" FROM "users" LEFT JOIN "roles" ON "users"."role_id" = "roles"."id" WHERE ("users"."id" = 1) ORDER BY users.id ASC LIMIT 1

  0.000801 seconds (16 allocations: 576 bytes)

2016-12-23T15:09:27.173 - info: SQL QUERY: SELECT "roles"."id" AS "roles_id", "roles"."name" AS "roles_name" FROM "roles" WHERE (roles.id = 2) LIMIT 1

  0.000470 seconds (13 allocations: 432 bytes)
'genie@example.com''; DROP users;'
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L2640-L2659' class='documenter-source'>source</a><br>

<a id='SearchLight.delete_all' href='#SearchLight.delete_all'>#</a>
**`SearchLight.delete_all`** &mdash; *Function*.



```
delete_all{T<:AbstractModel}(m::Type{T}; truncate::Bool = true, reset_sequence::Bool = true, cascade::Bool = false) :: Void
```

Deletes all the rows from the database table corresponding to `m`. If `truncate` is `true`, the table will be truncated. If `reset_sequence` is `true`, the auto-increment counter will be reset (where supported by the underlying RDBMS). If `cascade` is `true`, the delete will be cascaded to all related tables (where supported by the underlying RDBMS).

**Examples**

```julia
julia> SearchLight.delete_all(Article)
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L2685-L2696' class='documenter-source'>source</a><br>

<a id='SearchLight.delete' href='#SearchLight.delete'>#</a>
**`SearchLight.delete`** &mdash; *Function*.



```
delete{T<:AbstractModel}(m::T) :: T
```

Deletes the database row correspoding to `m` and returns a copy of `m` that is no longer persisted.

**Examples**

```julia
julia> SearchLight.delete(SearchLight.find_one!!(Article, 61))

2016-12-23T15:29:26.997 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles" WHERE ("articles"."id" = 61) ORDER BY articles.id ASC LIMIT 1

  0.003323 seconds (1.23 k allocations: 52.688 KB)

2016-12-23T15:29:29.856 - info: SQL QUERY: DELETE FROM articles WHERE id = '61'

  0.013913 seconds (5 allocations: 176 bytes)

App.Article
+==============+=========================================================================================================+
|          key |                                                                                                   value |
+==============+=========================================================================================================+
|      content | Pariatur maiores. Amet numquam ullam nostrum est. Excepturi..Pariatur maiores. Amet numquam ullam no... |
+--------------+---------------------------------------------------------------------------------------------------------+
|           id |                                                                                       Nullable{Int32}() |
+--------------+---------------------------------------------------------------------------------------------------------+
| published_at |                                                                                    Nullable{DateTime}() |
+--------------+---------------------------------------------------------------------------------------------------------+
|         slug | neque-repudiandae-sit-vel-laudantium-laboriosam-in-esse-modi-autem-ut-asperioresneque-repudiandae-si... |
+--------------+---------------------------------------------------------------------------------------------------------+
|      summary |                              Similique sunt. Cupiditate eligendi..Similique sunt. Cupiditate eligendi.. |
+--------------+---------------------------------------------------------------------------------------------------------+
|        title | Neque repudiandae sit vel. Laudantium laboriosam in. Esse modi autem ut asperiores..Neque repudianda... |
+--------------+---------------------------------------------------------------------------------------------------------+
|   updated_at |                                                                                 2016-11-28T22:18:48.723 |
+--------------+---------------------------------------------------------------------------------------------------------+
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L2702-L2738' class='documenter-source'>source</a><br>

<a id='SearchLight.query' href='#SearchLight.query'>#</a>
**`SearchLight.query`** &mdash; *Function*.



```
query(sql::String) :: DataFrame
```

Executes the `sql` SQL query string against the underlying database.

**Examples**

```julia
julia> SearchLight.query("SELECT * FROM articles LIMIT 5")

2016-12-23T15:35:58.617 - info: SQL QUERY: SELECT * FROM articles LIMIT 5

  0.117957 seconds (92.35 k allocations: 4.005 MB)

5×7 DataFrames.DataFrame
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L2748-L2763' class='documenter-source'>source</a><br>

<a id='SearchLight.count' href='#SearchLight.count'>#</a>
**`SearchLight.count`** &mdash; *Function*.



```
count{T<:AbstractModel}(m::Type{T}[, q::SQLQuery = SQLQuery()]) :: Int
```

Executes a count query against `m` applying `q`.

**Examples**

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


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L2779-L2800' class='documenter-source'>source</a><br>

<a id='SearchLight.disposable_instance' href='#SearchLight.disposable_instance'>#</a>
**`SearchLight.disposable_instance`** &mdash; *Function*.



```
disposable_instance{T<:AbstractModel}(m::Type{T}) :: T
```

Returns a type stable object T().


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L2811-L2815' class='documenter-source'>source</a><br>

<a id='SearchLight.clone' href='#SearchLight.clone'>#</a>
**`SearchLight.clone`** &mdash; *Function*.



```
clone{T<:SQLType}(o::T, fieldname::Symbol, value::Any) :: T
```

Creates a copy of `o` changing `fieldname` with `value`. To be used to change instances of immutable types.

**Examples**

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
|  scopes |                                                     Symbol[] |
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
|  scopes |                                                     Symbol[] |
+---------+--------------------------------------------------------------+
|   where | Union{SearchLight.SQLWhere,SearchLight.SQLWhereExpression}[] |
+---------+--------------------------------------------------------------+
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L2821-L2879' class='documenter-source'>source</a><br>


```
clone{T<:SQLType}(o::T, changes::Dict{Symbol,Any}) :: T
```

Creates a copy of `o` changing `fieldname` with `value`; or replacing the corresponding properties from `o` with the corresponding values from `changes`. To be used to change instances of immutable types.

**Examples**

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
|  scopes |                                                     Symbol[] |
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
|  scopes |                                                     Symbol[] |
+---------+--------------------------------------------------------------+
|   where | Union{SearchLight.SQLWhere,SearchLight.SQLWhereExpression}[] |
+---------+--------------------------------------------------------------+
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L2891-L2947' class='documenter-source'>source</a><br>

<a id='SearchLight.columns' href='#SearchLight.columns'>#</a>
**`SearchLight.columns`** &mdash; *Function*.



```
columns{T<:AbstractModel}(m::Type{T}) :: DataFrames.DataFrame
columns{T<:AbstractModel}(m::T) :: DataFrames.DataFrame
```

Returns a DataFrame representing schema information for the database table columns associated with `m`.


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L2959-L2964' class='documenter-source'>source</a><br>

<a id='SearchLight.is_persisted' href='#SearchLight.is_persisted'>#</a>
**`SearchLight.is_persisted`** &mdash; *Function*.



```
is_persisted{T<:AbstractModel}(m::T) :: Bool
```

Returns wheter or not the model object is persisted to the database.

**Examples**

```julia
julia> SearchLight.is_persisted(User())
false

julia> SearchLight.is_persisted(SearchLight.find_one!!(User, 1))

2016-12-23T16:44:24.805 - info: SQL QUERY: SELECT "users"."id" AS "users_id", "users"."name" AS "users_name", "users"."email" AS "users_email", "users"."password" AS "users_password", "users"."role_id" AS "users_role_id", "users"."updated_at" AS "users_updated_at", "roles"."id" AS "roles_id", "roles"."name" AS "roles_name" FROM "users" LEFT JOIN "roles" ON "users"."role_id" = "roles"."id" WHERE ("users"."id" = 1) ORDER BY users.id ASC LIMIT 1

  0.002438 seconds (1.23 k allocations: 52.688 KB)

2016-12-23T16:44:28.13 - info: SQL QUERY: SELECT "roles"."id" AS "roles_id", "roles"."name" AS "roles_name" FROM "roles" WHERE (roles.id = 2) LIMIT 1

  0.000599 seconds (13 allocations: 432 bytes)
true
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L2973-L2994' class='documenter-source'>source</a><br>

<a id='SearchLight.persistable_fields' href='#SearchLight.persistable_fields'>#</a>
**`SearchLight.persistable_fields`** &mdash; *Function*.



```
persistable_fields{T<:AbstractModel}(m::T; fully_qualified::Bool = false) :: Vector{String}
```

Returns a vector containing the names of the fields of `m` that are mapped to corresponding database columns. The `fully_qualified` param will prepend the name of the table and add an automatically generated alias.

**Examples**

```julia
julia> SearchLight.persistable_fields(SearchLight.find_one!!(User, 1))

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

 julia> SearchLight.persistable_fields(SearchLight.find_one!!(User, 1), fully_qualified = true)

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


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L3000-L3044' class='documenter-source'>source</a><br>

<a id='SearchLight.settable_fields' href='#SearchLight.settable_fields'>#</a>
**`SearchLight.settable_fields`** &mdash; *Function*.



```
settable_fields{T<:AbstractModel}(m::T, row::DataFrames.DataFrameRow) :: Vector{Symbol}
```

???


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L3058-L3062' class='documenter-source'>source</a><br>

<a id='SearchLight.id' href='#SearchLight.id'>#</a>
**`SearchLight.id`** &mdash; *Function*.



```
id{T<:AbstractModel}(m::T) :: String
```

Returns the "id" property defined on `m`.


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L3076-L3080' class='documenter-source'>source</a><br>

<a id='SearchLight.table_name' href='#SearchLight.table_name'>#</a>
**`SearchLight.table_name`** &mdash; *Function*.



```
table_name{T<:AbstractModel}(m::T) :: String
```

Returns the table_name property defined on `m`.


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L3086-L3090' class='documenter-source'>source</a><br>

<a id='SearchLight.validator!!' href='#SearchLight.validator!!'>#</a>
**`SearchLight.validator!!`** &mdash; *Function*.



```
validator!!{T<:AbstractModel}(m::T) :: ModelValidator
```

Gets the ModelValidator object defined for `m`. If no ModelValidator is defined, an error will be thrown.

**Examples**

```julia
julia> ar = SearchLight.rand_one!!(Article)

App.Article
+==============+==========================================================================================+
|          key |                                                                                    value |
+==============+==========================================================================================+
|           id |                                                                      Nullable{Int32}(16) |
+--------------+------------------------------------------------------------------------------------------+
...

julia> SearchLight.validator!!(ar)

SearchLight.ModelValidator
+========+=========================================================================================================+
|    key |                                                                                                   value |
+========+=========================================================================================================+
| errors |                                                                           Tuple{Symbol,Symbol,String}[] |
+--------+---------------------------------------------------------------------------------------------------------+
|  rules | Tuple{Symbol,Function,Vararg{Any,N}}[(:title,Validation.not_empty),(:title,Validation.min_length,20)... |
+--------+---------------------------------------------------------------------------------------------------------+
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L3096-L3125' class='documenter-source'>source</a><br>

<a id='SearchLight.validator' href='#SearchLight.validator'>#</a>
**`SearchLight.validator`** &mdash; *Function*.



```
validator{T<:AbstractModel}(m::T) :: Nullable{ModelValidator}
```

Gets the ModelValidator object defined for `m` wrapped in a Nullable{ModelValidator}.

**Examples**

```julia
julia> SearchLight.rand_one!!(Article) |> SearchLight.validator

Nullable{SearchLight.ModelValidator}(
SearchLight.ModelValidator
+========+=========================================================================================================+
|    key |                                                                                                   value |
+========+=========================================================================================================+
| errors |                                                                           Tuple{Symbol,Symbol,String}[] |
+--------+---------------------------------------------------------------------------------------------------------+
|  rules | Tuple{Symbol,Function,Vararg{Any,N}}[(:title,Validation.not_empty),(:title,Validation.min_length,20)... |
+--------+---------------------------------------------------------------------------------------------------------+
)
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L3131-L3151' class='documenter-source'>source</a><br>

<a id='SearchLight.has_field' href='#SearchLight.has_field'>#</a>
**`SearchLight.has_field`** &mdash; *Function*.



```
has_field{T<:AbstractModel}(m::T, f::Symbol) :: Bool
```

Returns a `Bool` whether or not the field `f` is defined on the model `m`.

**Examples**

```julia
julia> SearchLight.has_field(ar, :validator)
true

julia> SearchLight.has_field(ar, :moo)
false
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L3157-L3170' class='documenter-source'>source</a><br>

<a id='SearchLight.strip_table_name' href='#SearchLight.strip_table_name'>#</a>
**`SearchLight.strip_table_name`** &mdash; *Function*.



```
strip_table_name{T<:AbstractModel}(m::T, f::Symbol) :: Symbol
```

Strips the table name associated with the model from a fully qualified alias column name string.

**Examples**

```julia
julia> SearchLight.strip_table_name(SearchLight.rand_one!!(Article), :articles_updated_at)
:updated_at
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L3176-L3186' class='documenter-source'>source</a><br>

<a id='SearchLight.is_fully_qualified' href='#SearchLight.is_fully_qualified'>#</a>
**`SearchLight.is_fully_qualified`** &mdash; *Function*.



```
is_fully_qualified{T<:AbstractModel}(m::T, f::Symbol) :: Bool
is_fully_qualified{T<:SQLType}(t::T) :: Bool
```

Returns a `Bool` whether or not `f` represents a fully qualified column name alias of the table associated with the model `m`.

**Examples**

```julia
julia> SearchLight.is_fully_qualified(SearchLight.rand_one!!(Article), :articles_updated_at)
true

julia> SearchLight.is_fully_qualified(SearchLight.rand_one!!(Article), :users_updated_at)
false
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L3192-L3206' class='documenter-source'>source</a><br>


```
is_fully_qualified(s::String) :: Bool
```

Returns a `Bool` whether or not `s` represents a fully qualified SQL column name.

**Examples**

```julia
julia> SearchLight.is_fully_qualified("articles.updated_at")
true

julia> SearchLight.is_fully_qualified("updated_at")
false
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L3215-L3228' class='documenter-source'>source</a><br>

<a id='SearchLight.from_fully_qualified' href='#SearchLight.from_fully_qualified'>#</a>
**`SearchLight.from_fully_qualified`** &mdash; *Function*.



```
from_fully_qualified{T<:AbstractModel}(m::T, f::Symbol) :: String
```

If `f` is a fully qualified column name alias of the table associated with the model `m`, it returns the column name with the table name stripped off. Otherwise it returns `f`.

**Examples**

```julia
julia> SearchLight.from_fully_qualified(SearchLight.rand_one!!(Article), :articles_updated_at)
:updated_at

julia> SearchLight.from_fully_qualified(SearchLight.rand_one!!(Article), :foo_bar)
:foo_bar
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L3234-L3248' class='documenter-source'>source</a><br>


```
from_fully_qualified(s::String) :: Tuple{String,String}
```

Attempts to split a fully qualified SQL column name into a Tuple of table_name and column_name. If `s` is not in the table_name.column_name format, an error is thrown.

**Examples**

```julia
julia> SearchLight.from_fully_qualified("articles.updated_at")
("articles","updated_at")

julia> SearchLight.from_fully_qualified("articles_updated_at")
------ String -------------------------- Stacktrace (most recent call last)

 [1] — from_fully_qualified(::String) at SearchLight.jl:3168

"articles_updated_at is not a fully qualified SQL column name in the format table_name.column_name"
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L3254-L3272' class='documenter-source'>source</a><br>

<a id='SearchLight.strip_module_name' href='#SearchLight.strip_module_name'>#</a>
**`SearchLight.strip_module_name`** &mdash; *Function*.



```
strip_module_name(s::String) :: String
```

If `s` is in the format module_name.function_name, only the function name will be returned. Otherwise `s` will be returned.

**Examples**

```julia
julia> SearchLight.strip_module_name("SearchLight.rand")
"rand"
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L3285-L3296' class='documenter-source'>source</a><br>

<a id='SearchLight.to_fully_qualified' href='#SearchLight.to_fully_qualified'>#</a>
**`SearchLight.to_fully_qualified`** &mdash; *Function*.



```
to_fully_qualified(v::String, t::String) :: String
```

Takes `v` as the column name and `t` as the table name and returns a fully qualified SQL column name as `table_name.column_name`.

**Examples**

```julia
julia> SearchLight.to_fully_qualified("updated_at", "articles")
"articles.updated_at"
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L3302-L3312' class='documenter-source'>source</a><br>


```
to_fully_qualified{T<:AbstractModel}(m::T, v::String) :: String
to_fully_qualified{T<:AbstractModel}(m::T, c::SQLColumn) :: String
to_fully_qualified{T<:AbstractModel}(m::Type{T}, c::SQLColumn) :: String
```

Returns the fully qualified SQL column name corresponding to the column `v` and the model `m`.

**Examples**

```julia
julia> SearchLight.to_fully_qualified(SearchLight.rand_one!!(Article), "updated_at")
"articles.updated_at"
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L3318-L3330' class='documenter-source'>source</a><br>

<a id='SearchLight.to_sql_column_names' href='#SearchLight.to_sql_column_names'>#</a>
**`SearchLight.to_sql_column_names`** &mdash; *Function*.



```
to_sql_column_names{T<:AbstractModel}(m::T, fields::Vector{Symbol}) :: Vector{Symbol}
```

Takes a model `m` and a Vector{Symbol} corresponding to unqualified SQL column names and returns a Vector{Symbol} of fully qualified alias columns.

**Examples**

```julia
julia> SearchLight.to_sql_column_names(SearchLight.rand_one!!(Article), Symbol[:updated_at, :deleted])
2-element Array{Symbol,1}:
 :articles_updated_at
 :articles_deleted
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L3343-L3355' class='documenter-source'>source</a><br>

<a id='SearchLight.to_sql_column_name' href='#SearchLight.to_sql_column_name'>#</a>
**`SearchLight.to_sql_column_name`** &mdash; *Function*.



```
to_sql_column_name(v::String, t::String) :: String
```

Generates a column name in the form `table_column` from `t` and `v` as `t_v`.


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L3361-L3365' class='documenter-source'>source</a><br>

<a id='SearchLight.to_fully_qualified_sql_column_names' href='#SearchLight.to_fully_qualified_sql_column_names'>#</a>
**`SearchLight.to_fully_qualified_sql_column_names`** &mdash; *Function*.



```
to_fully_qualified_sql_column_names{T<:AbstractModel}(m::T, persistable_fields::Vector{String}; escape_columns::Bool = false) :: Vector{String}
```

Takes a `vector` of field names and generates corresponding SQL column names.


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L3382-L3386' class='documenter-source'>source</a><br>

<a id='SearchLight.to_fully_qualified_sql_column_name' href='#SearchLight.to_fully_qualified_sql_column_name'>#</a>
**`SearchLight.to_fully_qualified_sql_column_name`** &mdash; *Function*.



```
to_fully_qualified_sql_column_name{T<:AbstractModel}(m::T, f::String; escape_columns::Bool = false, alias::String = "") :: String
```

Generates a fully qualified SQL column name, in the form of `table_name.column AS table_name_column` for the underlying table of `m` and the column `f`.


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L3392-L3396' class='documenter-source'>source</a><br>

<a id='SearchLight.from_literal_column_name' href='#SearchLight.from_literal_column_name'>#</a>
**`SearchLight.from_literal_column_name`** &mdash; *Function*.



```
from_literal_column_name(c::String) :: Dict{Symbol,String}
```

Takes a SQL column name `c` and returns a `Dict` of its parts (`:column_name`, `:alias`, `:original_string`)


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L3406-L3410' class='documenter-source'>source</a><br>

<a id='SearchLight.to_dict' href='#SearchLight.to_dict'>#</a>
**`SearchLight.to_dict`** &mdash; *Function*.



```
to_dict{T<:AbstractModel}(m::T; all_fields::Bool = false) :: Dict{String,Any}
```

Converts a model `m` to a `Dict`. Orginal types of the fields values are kept. If `all_fields` is `true`, all fields are included; otherwise just the fields corresponding to database columns.


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L3435-L3440' class='documenter-source'>source</a><br>


```
to_dict(m::Any) :: Dict{String,Any}
```

Creates a `Dict` using the fields and the values of `m`.


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L3447-L3451' class='documenter-source'>source</a><br>

<a id='SearchLight.to_string_dict' href='#SearchLight.to_string_dict'>#</a>
**`SearchLight.to_string_dict`** &mdash; *Function*.



```
to_string_dict{T<:AbstractModel}(m::T; all_fields::Bool = false, all_output::Bool = false) :: Dict{String,String}
```

Converts a model `m` to a `Dict{String,String}`. Orginal types of the fields values are converted to strings. If `all_fields` is `true`, all fields are included; otherwise just the fields corresponding to database columns. If `all_output` is `false` the values are truncated if longer than `output_length`.


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L3457-L3463' class='documenter-source'>source</a><br>

<a id='SearchLight.to_nullable' href='#SearchLight.to_nullable'>#</a>
**`SearchLight.to_nullable`** &mdash; *Function*.



```
to_nullable{T<:AbstractModel}(result::Vector{T}) :: Nullable{T}
```

Wraps a result vector into a `Nullable`.


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L3498-L3502' class='documenter-source'>source</a><br>

<a id='SearchLight.has_relation' href='#SearchLight.has_relation'>#</a>
**`SearchLight.has_relation`** &mdash; *Function*.



```
has_relation{T<:AbstractModel}(m::T, relation_type::Symbol) :: Bool
```

Returns wheter or not the model `m` has defined a relation of type `relation_type`.


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L3508-L3512' class='documenter-source'>source</a><br>

<a id='SearchLight.dataframe_to_dict' href='#SearchLight.dataframe_to_dict'>#</a>
**`SearchLight.dataframe_to_dict`** &mdash; *Function*.



```
dataframe_to_dict(df::DataFrames.DataFrame) :: Vector{Dict{Symbol,Any}}
```

Converts a `DataFrame` to a `Vector{Dict{Symbol,Any}}`.


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L3518-L3522' class='documenter-source'>source</a><br>

<a id='SearchLight.enclosure' href='#SearchLight.enclosure'>#</a>
**`SearchLight.enclosure`** &mdash; *Function*.



```
enclosure(v::Any, o::Any) :: String
```

Wraps SQL query parts in parenthesys.


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/SearchLight.jl#L3533-L3537' class='documenter-source'>source</a><br>

<a id='SearchLight.ModelValidator' href='#SearchLight.ModelValidator'>#</a>
**`SearchLight.ModelValidator`** &mdash; *Type*.



The object that defines the rules and stores the validation errors associated with the fields of a `model`.


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/model_types.jl#L47-L49' class='documenter-source'>source</a><br>

<a id='SearchLight.SQLInput' href='#SearchLight.SQLInput'>#</a>
**`SearchLight.SQLInput`** &mdash; *Type*.



Provides safe input into SQL queries and operations related to that.


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/model_types.jl#L62-L64' class='documenter-source'>source</a><br>

<a id='SearchLight.escape_value' href='#SearchLight.escape_value'>#</a>
**`SearchLight.escape_value`** &mdash; *Function*.



```
escape_value(i::SQLInput)
```

Sanitizes input to be used as values in SQL queries.


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/model_types.jl#L100-L104' class='documenter-source'>source</a><br>

<a id='SearchLight.SQLColumn' href='#SearchLight.SQLColumn'>#</a>
**`SearchLight.SQLColumn`** &mdash; *Type*.



Represents a SQL column when building SQL queries.


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/model_types.jl#L122-L124' class='documenter-source'>source</a><br>

<a id='SearchLight.escape_column_name' href='#SearchLight.escape_column_name'>#</a>
**`SearchLight.escape_column_name`** &mdash; *Function*.



```
escape_column_name(c::SQLColumn) :: SQLColumn
escape_column_name(s::String)
```

Sanitizes input to be use as column names in SQL queries.


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/model_types.jl#L165-L170' class='documenter-source'>source</a><br>

<a id='SearchLight.SQLLogicOperator' href='#SearchLight.SQLLogicOperator'>#</a>
**`SearchLight.SQLLogicOperator`** &mdash; *Type*.



Represents the logic operators (OR, AND) as part of SQL queries.


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/model_types.jl#L196-L198' class='documenter-source'>source</a><br>

<a id='SearchLight.SQLWhere' href='#SearchLight.SQLWhere'>#</a>
**`SearchLight.SQLWhere`** &mdash; *Type*.



Provides functionality for building and manipulating SQL `WHERE` conditions.


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/model_types.jl#L213-L215' class='documenter-source'>source</a><br>

<a id='SearchLight.SQLWhereExpression' href='#SearchLight.SQLWhereExpression'>#</a>
**`SearchLight.SQLWhereExpression`** &mdash; *Type*.



```
SQLWhereExpression(sql_expression::String, values::T)
SQLWhereExpression(sql_expression::String[, values::Vector{T}])
```

Constructs an instance of SQLWhereExpression, replacing the `?` placeholders inside `sql_expression` with properly quoted values.

**Examples:**

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

julia> SQLWhereExpression("question LIKE 'what is the question\?'")

SearchLight.SQLWhereExpression
+================+========================================+
|            key |                                  value |
+================+========================================+
|      condition |                                    AND |
+----------------+----------------------------------------+
| sql_expression | question LIKE 'what is the question?' |
+----------------+----------------------------------------+
|         values |                                        |
+----------------+----------------------------------------+
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/model_types.jl#L246-L294' class='documenter-source'>source</a><br>

<a id='SearchLight.SQLLimit' href='#SearchLight.SQLLimit'>#</a>
**`SearchLight.SQLLimit`** &mdash; *Type*.



Wrapper around SQL `limit` operator.


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/model_types.jl#L339-L341' class='documenter-source'>source</a><br>

<a id='SearchLight.SQLOrder' href='#SearchLight.SQLOrder'>#</a>
**`SearchLight.SQLOrder`** &mdash; *Type*.



Wrapper around SQL `order` operator.


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/model_types.jl#L370-L372' class='documenter-source'>source</a><br>

<a id='SearchLight.SQLOn' href='#SearchLight.SQLOn'>#</a>
**`SearchLight.SQLOn`** &mdash; *Type*.



Represents the `ON` operator used in SQL `JOIN`


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/model_types.jl#L407-L409' class='documenter-source'>source</a><br>

<a id='SearchLight.SQLJoinType' href='#SearchLight.SQLJoinType'>#</a>
**`SearchLight.SQLJoinType`** &mdash; *Type*.



Wrapper around the various types of SQL `join` (`left`, `right`, `inner`, etc).


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/model_types.jl#L431-L433' class='documenter-source'>source</a><br>

<a id='SearchLight.SQLJoin' href='#SearchLight.SQLJoin'>#</a>
**`SearchLight.SQLJoin`** &mdash; *Type*.



Builds and manipulates SQL `join` expressions.


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/model_types.jl#L456-L458' class='documenter-source'>source</a><br>

<a id='SearchLight.SQLQuery' href='#SearchLight.SQLQuery'>#</a>
**`SearchLight.SQLQuery`** &mdash; *Type*.



```
SQLQuery( columns = SQLColumn[],
          where   = SQLWhereEntity[],
          limit   = SQLLimit("ALL"),
          offset  = 0,
          order   = SQLOrder[],
          group   = SQLColumn[],
          having  = SQLWhereEntity[],
          scopes  = Symbol[] )
```

Returns a new instance of SQLQuery.

**Examples**

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


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/model_types.jl#L495-L538' class='documenter-source'>source</a><br>

<a id='SearchLight.SQLRelationData' href='#SearchLight.SQLRelationData'>#</a>
**`SearchLight.SQLRelationData`** &mdash; *Type*.



Represents the data contained by a SQL relation.


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/model_types.jl#L561-L563' class='documenter-source'>source</a><br>

<a id='SearchLight.SQLRelation' href='#SearchLight.SQLRelation'>#</a>
**`SearchLight.SQLRelation`** &mdash; *Type*.



Defines the relation between two models, as reflected by the relation of their underlying SQL tables.


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/model_types.jl#L573-L575' class='documenter-source'>source</a><br>

