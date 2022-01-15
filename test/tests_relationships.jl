#==

using SearchLight, SearchLight.Migrations, SearchLight.Relationships

cd(joinpath(pathof(SearchLight) |> dirname, "..", "test"))

### SQLite
using SearchLightSQLite
const conndata = Dict("database" => "db/testdb.sqlite", "adapter" => "SQLite")

### MySQL
# using SearchLightMySQL
# const conndata = Dict{String,Any}("host" => "localhost", "database" => "testdb", "username" => "root", "password" => "root", "adapter" => "MySQL")

### Postgres
# using SearchLightPostgreSQL
# const conndata = Dict{String,Any}("host" => "localhost", "database" => "testdb", "username" => "postgres", "adapter" => "PostgreSQL")


const conn = SearchLight.connect(conndata)

try
  SearchLight.Migrations.status()
catch _
  SearchLight.Migrations.create_migrations_table()
end

isempty(SearchLight.Migrations.downed_migrations()) || SearchLight.Migrations.all_up!!()

Base.@kwdef mutable struct User <: AbstractModel
  id::DbId = DbId()
  username::String = ""
  password::String = ""
  name::String = ""
  email::String = ""
end

Base.@kwdef mutable struct Role <: AbstractModel
  id::DbId = DbId()
  name::String = ""
end

Base.@kwdef mutable struct Ability <: AbstractModel
  id::DbId = DbId()
  name::String = ""
end

u1 = findone_or_create(User, username = "a") |> save!
r1 = findone_or_create(Role, name = "abcd") |> save!

for x in 'a':'d'
  findone_or_create(Ability, name = "$x") |> save!
end

Relationships.Relationship!(u1, r1)

for a in all(Ability)
  Relationships.Relationship!(r1, a)
end

Relationships.related(u1, Role)
Relationships.related(findone(Role, id = 1), Ability)
Relationships.related(u1, Ability, through = [Role])

=#