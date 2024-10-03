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
    warnonly = true,
    pages = [
        "Home" => "index.md",
        "SearchLight API" => [
          "Callbacks" => "API/callbacks.md",
          "Configuration" => "API/configuration.md",
          "Exceptions" => "API/exceptions.md",
          "FileTemplates" => "API/filetemplates.md",
          "Generator" => "API/generator.md",
          "Migrations" => "API/migrations.md",
          "ModelTypes" => "API/modeltypes.md",
          "QueryBuilder" => "API/querybuilder.md",
          "Relationships" => "API/relationships.md",
          "SearchLight" => "API/searchlight.md",
          "Serializer" => "API/serializer.md",
          "Serializers" => [
            "JsonSerializer" => "API/serializers/json.md",
          ],
          "Transactions" => "API/transactions.md",
          "Validation" => "API/validation.md",
        ]
    ],
)

deploydocs(
  repo = "github.com/GenieFramework/SearchLight.jl.git",
)
