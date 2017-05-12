

- [Genie / SearchLight](index.md#Genie-/-SearchLight-1)

<a id='PostgreSQLDatabaseAdapter.db_adapter' href='#PostgreSQLDatabaseAdapter.db_adapter'>#</a>
**`PostgreSQLDatabaseAdapter.db_adapter`** &mdash; *Function*.



```
db_adapter() :: Symbol
```

The name of the underlying database adapter (driver).


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/database_adapters/PostgreSQLDatabaseAdapter.jl#L20-L24' class='documenter-source'>source</a><br>

<a id='PostgreSQLDatabaseAdapter.connect' href='#PostgreSQLDatabaseAdapter.connect'>#</a>
**`PostgreSQLDatabaseAdapter.connect`** &mdash; *Function*.



```
connect(conn_data::Dict{String,Any}) :: DatabaseHandle
```

Connects to the database and returns a handle.


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/database_adapters/PostgreSQLDatabaseAdapter.jl#L35-L39' class='documenter-source'>source</a><br>

<a id='PostgreSQLDatabaseAdapter.create_database' href='#PostgreSQLDatabaseAdapter.create_database'>#</a>
**`PostgreSQLDatabaseAdapter.create_database`** &mdash; *Function*.



```
create_database(db_name::String) :: Bool
```

Creates the database `db_name`. Returns `true` on success - `false` on failure


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/database_adapters/PostgreSQLDatabaseAdapter.jl#L63-L67' class='documenter-source'>source</a><br>

<a id='PostgreSQLDatabaseAdapter.table_columns_sql' href='#PostgreSQLDatabaseAdapter.table_columns_sql'>#</a>
**`PostgreSQLDatabaseAdapter.table_columns_sql`** &mdash; *Function*.



```
table_columns_sql(table_name::AbstractString) :: String
```

Returns the adapter specific query for SELECTing table columns information corresponding to `table_name`.


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/database_adapters/PostgreSQLDatabaseAdapter.jl#L73-L77' class='documenter-source'>source</a><br>

<a id='PostgreSQLDatabaseAdapter.create_migrations_table' href='#PostgreSQLDatabaseAdapter.create_migrations_table'>#</a>
**`PostgreSQLDatabaseAdapter.create_migrations_table`** &mdash; *Function*.



```
create_migrations_table(table_name::String) :: Bool
```

Runs a SQL DB query that creates the table `table_name` with the structure needed to be used as the DB migrations table. The table should contain one column, `version`, unique, as a string of maximum 30 chars long. Returns `true` on success.


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/database_adapters/PostgreSQLDatabaseAdapter.jl#L87-L93' class='documenter-source'>source</a><br>

<a id='PostgreSQLDatabaseAdapter.escape_column_name' href='#PostgreSQLDatabaseAdapter.escape_column_name'>#</a>
**`PostgreSQLDatabaseAdapter.escape_column_name`** &mdash; *Function*.



```
escape_column_name(c::AbstractString, conn::DatabaseHandle) :: String
```

Escapes the column name using native features provided by the database backend.

**Examples**

```julia
julia> PostgreSQLDatabaseAdapter.escape_column_name("foo"; DROP moo;", Database.connection())
""foo""; DROP moo;""
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/database_adapters/PostgreSQLDatabaseAdapter.jl#L108-L118' class='documenter-source'>source</a><br>

<a id='PostgreSQLDatabaseAdapter.escape_value' href='#PostgreSQLDatabaseAdapter.escape_value'>#</a>
**`PostgreSQLDatabaseAdapter.escape_value`** &mdash; *Function*.



```
escape_value{T}(v::T, conn::DatabaseHandle) :: T
```

Escapes the value `v` using native features provided by the database backend.

**Examples**

```julia
julia> PostgreSQLDatabaseAdapter.escape_value("'; DROP moo;", Database.connection())
"'''; DROP moo;'"

julia> PostgreSQLDatabaseAdapter.escape_value(SQLInput(22), Database.connection())
22

julia> PostgreSQLDatabaseAdapter.escape_value(SQLInput("hello"), Database.connection())
'hello'
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/database_adapters/PostgreSQLDatabaseAdapter.jl#L128-L144' class='documenter-source'>source</a><br>

<a id='PostgreSQLDatabaseAdapter.query_df' href='#PostgreSQLDatabaseAdapter.query_df'>#</a>
**`PostgreSQLDatabaseAdapter.query_df`** &mdash; *Function*.



```
query_df(sql::AbstractString, suppress_output::Bool, conn::DatabaseHandle) :: DataFrames.DataFrame
```

Executes the `sql` query against the database backend and returns a DataFrame result.

**Examples:**

```julia
julia> PostgreSQLDatabaseAdapter.query_df(SearchLight.to_fetch_sql(Article, SQLQuery(limit = 5)), false, Database.connection())

2017-01-16T21:36:21.566 - info: SQL QUERY: SELECT "articles"."id" AS "articles_id", "articles"."title" AS "articles_title", "articles"."summary" AS "articles_summary", "articles"."content" AS "articles_content", "articles"."updated_at" AS "articles_updated_at", "articles"."published_at" AS "articles_published_at", "articles"."slug" AS "articles_slug" FROM "articles" LIMIT 5

  0.000985 seconds (16 allocations: 576 bytes)

5×7 DataFrames.DataFrame
...
```


<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/database_adapters/PostgreSQLDatabaseAdapter.jl#L155-L171' class='documenter-source'>source</a><br>

<a id='PostgreSQLDatabaseAdapter.query' href='#PostgreSQLDatabaseAdapter.query'>#</a>
**`PostgreSQLDatabaseAdapter.query`** &mdash; *Function*.





<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/database_adapters/PostgreSQLDatabaseAdapter.jl#L177-L179' class='documenter-source'>source</a><br>

<a id='PostgreSQLDatabaseAdapter.relation_to_sql' href='#PostgreSQLDatabaseAdapter.relation_to_sql'>#</a>
**`PostgreSQLDatabaseAdapter.relation_to_sql`** &mdash; *Function*.





<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/database_adapters/PostgreSQLDatabaseAdapter.jl#L199-L201' class='documenter-source'>source</a><br>

<a id='PostgreSQLDatabaseAdapter.to_find_sql' href='#PostgreSQLDatabaseAdapter.to_find_sql'>#</a>
**`PostgreSQLDatabaseAdapter.to_find_sql`** &mdash; *Function*.





<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/database_adapters/PostgreSQLDatabaseAdapter.jl#L220-L222' class='documenter-source'>source</a><br>

<a id='PostgreSQLDatabaseAdapter.to_store_sql' href='#PostgreSQLDatabaseAdapter.to_store_sql'>#</a>
**`PostgreSQLDatabaseAdapter.to_store_sql`** &mdash; *Function*.





<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/database_adapters/PostgreSQLDatabaseAdapter.jl#L238-L240' class='documenter-source'>source</a><br>

<a id='PostgreSQLDatabaseAdapter.delete_all' href='#PostgreSQLDatabaseAdapter.delete_all'>#</a>
**`PostgreSQLDatabaseAdapter.delete_all`** &mdash; *Function*.





<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/database_adapters/PostgreSQLDatabaseAdapter.jl#L266-L268' class='documenter-source'>source</a><br>

<a id='PostgreSQLDatabaseAdapter.delete' href='#PostgreSQLDatabaseAdapter.delete'>#</a>
**`PostgreSQLDatabaseAdapter.delete`** &mdash; *Function*.





<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/database_adapters/PostgreSQLDatabaseAdapter.jl#L285-L287' class='documenter-source'>source</a><br>

<a id='PostgreSQLDatabaseAdapter.count' href='#PostgreSQLDatabaseAdapter.count'>#</a>
**`PostgreSQLDatabaseAdapter.count`** &mdash; *Function*.





<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/database_adapters/PostgreSQLDatabaseAdapter.jl#L299-L301' class='documenter-source'>source</a><br>

<a id='PostgreSQLDatabaseAdapter.update_query_part' href='#PostgreSQLDatabaseAdapter.update_query_part'>#</a>
**`PostgreSQLDatabaseAdapter.update_query_part`** &mdash; *Function*.





<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/database_adapters/PostgreSQLDatabaseAdapter.jl#L310-L312' class='documenter-source'>source</a><br>

<a id='PostgreSQLDatabaseAdapter.column_data_to_column_name' href='#PostgreSQLDatabaseAdapter.column_data_to_column_name'>#</a>
**`PostgreSQLDatabaseAdapter.column_data_to_column_name`** &mdash; *Function*.





<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/database_adapters/PostgreSQLDatabaseAdapter.jl#L320-L322' class='documenter-source'>source</a><br>

<a id='PostgreSQLDatabaseAdapter.to_select_part' href='#PostgreSQLDatabaseAdapter.to_select_part'>#</a>
**`PostgreSQLDatabaseAdapter.to_select_part`** &mdash; *Function*.





<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/database_adapters/PostgreSQLDatabaseAdapter.jl#L328-L330' class='documenter-source'>source</a><br>

<a id='PostgreSQLDatabaseAdapter.to_from_part' href='#PostgreSQLDatabaseAdapter.to_from_part'>#</a>
**`PostgreSQLDatabaseAdapter.to_from_part`** &mdash; *Function*.





<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/database_adapters/PostgreSQLDatabaseAdapter.jl#L336-L338' class='documenter-source'>source</a><br>

<a id='PostgreSQLDatabaseAdapter.to_where_part' href='#PostgreSQLDatabaseAdapter.to_where_part'>#</a>
**`PostgreSQLDatabaseAdapter.to_where_part`** &mdash; *Function*.





<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/database_adapters/PostgreSQLDatabaseAdapter.jl#L344-L346' class='documenter-source'>source</a><br>

<a id='PostgreSQLDatabaseAdapter.required_scopes' href='#PostgreSQLDatabaseAdapter.required_scopes'>#</a>
**`PostgreSQLDatabaseAdapter.required_scopes`** &mdash; *Function*.





<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/database_adapters/PostgreSQLDatabaseAdapter.jl#L366-L368' class='documenter-source'>source</a><br>

<a id='PostgreSQLDatabaseAdapter.scopes' href='#PostgreSQLDatabaseAdapter.scopes'>#</a>
**`PostgreSQLDatabaseAdapter.scopes`** &mdash; *Function*.





<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/database_adapters/PostgreSQLDatabaseAdapter.jl#L375-L377' class='documenter-source'>source</a><br>

<a id='PostgreSQLDatabaseAdapter.to_order_part' href='#PostgreSQLDatabaseAdapter.to_order_part'>#</a>
**`PostgreSQLDatabaseAdapter.to_order_part`** &mdash; *Function*.





<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/database_adapters/PostgreSQLDatabaseAdapter.jl#L383-L385' class='documenter-source'>source</a><br>

<a id='PostgreSQLDatabaseAdapter.to_group_part' href='#PostgreSQLDatabaseAdapter.to_group_part'>#</a>
**`PostgreSQLDatabaseAdapter.to_group_part`** &mdash; *Function*.





<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/database_adapters/PostgreSQLDatabaseAdapter.jl#L393-L395' class='documenter-source'>source</a><br>

<a id='PostgreSQLDatabaseAdapter.to_limit_part' href='#PostgreSQLDatabaseAdapter.to_limit_part'>#</a>
**`PostgreSQLDatabaseAdapter.to_limit_part`** &mdash; *Function*.





<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/database_adapters/PostgreSQLDatabaseAdapter.jl#L403-L405' class='documenter-source'>source</a><br>

<a id='PostgreSQLDatabaseAdapter.to_offset_part' href='#PostgreSQLDatabaseAdapter.to_offset_part'>#</a>
**`PostgreSQLDatabaseAdapter.to_offset_part`** &mdash; *Function*.





<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/database_adapters/PostgreSQLDatabaseAdapter.jl#L411-L413' class='documenter-source'>source</a><br>

<a id='PostgreSQLDatabaseAdapter.to_having_part' href='#PostgreSQLDatabaseAdapter.to_having_part'>#</a>
**`PostgreSQLDatabaseAdapter.to_having_part`** &mdash; *Function*.





<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/database_adapters/PostgreSQLDatabaseAdapter.jl#L419-L421' class='documenter-source'>source</a><br>

<a id='PostgreSQLDatabaseAdapter.to_join_part' href='#PostgreSQLDatabaseAdapter.to_join_part'>#</a>
**`PostgreSQLDatabaseAdapter.to_join_part`** &mdash; *Function*.





<a target='_blank' href='https://github.com/essenciary/SearchLight.jl/tree/c4751ae0ee42627d486e0dad39da3972c3bba221/src/database_adapters/PostgreSQLDatabaseAdapter.jl#L431-L433' class='documenter-source'>source</a><br>

