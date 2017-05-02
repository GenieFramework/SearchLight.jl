using Documenter, SearchLight, Validation, PostgreSQLDatabaseAdapter, Database

push!(LOAD_PATH,  "../../src")
push!(LOAD_PATH,  "../../src/database_adapters")

makedocs()
