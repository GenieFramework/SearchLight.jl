using Documenter

push!(LOAD_PATH,  "../../src")
push!(LOAD_PATH,  "../../serializers")

using SearchLight, SearchLight.Callbacks, SearchLight.Configuration, SearchLight.Exceptions
using SearchLight.Generator.FileTemplates, SearchLight.Generator, SearchLight.Migrations, SearchLight.QueryBuilder
using SearchLight.Relationships, SearchLight.Serializer, SearchLight.Transactions, SearchLight.Validation
using SearchLight.Serializer.JsonSerializer

makedocs(
    sitename = "SearchLight - Concise, secure, cross-platform query builder and ORM for Julia",
    format = Documenter.HTML(prettyurls = false),
    pages = [
        "Home" => "index.md",
        "SearchLight API" => [
          "Callbacks" => "api/callbacks.md",
          "Configuration" => "api/configuration.md",
          "Exceptions" => "api/exceptions.md",
          "FileTemplates" => "api/filetemplates.md",
          "Generator" => "api/generator.md",
          "Migrations" => "api/migrations.md",
          "ModelTypes" => "api/modeltypes.md",
          "QueryBuilder" => "api/querybuilder.md",
          "Relationships" => "api/relationships.md",
          "SearchLight" => "api/searchlight.md",
          "Serializer" => "api/serializer.md",
          "Serializers" => [
            "JsonSerializer" => "api/serializers/json.md",
          ],
          "Transactions" => "api/transactions.md",
          "Validation" => "api/validation.md",
        ]
    ],
)

deploydocs(
  repo = "github.com/GenieFramework/SearchLight.jl.git",
)
