using Documenter, SearchLight, Validation, PostgreSQLDatabaseAdapter

push!(LOAD_PATH,  "../../src")
push!(LOAD_PATH,  "../../src/adapters")

makedocs()