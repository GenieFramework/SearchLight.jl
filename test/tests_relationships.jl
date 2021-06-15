using SearchLight, SearchLightSQLite
using SearchLight.Migrations, SearchLight.Relationships

const conndata = Dict("database" => "db/testdb.sqlite", "adapter" => "SQLite")
const conn = SearchLight.connect(conndata)

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