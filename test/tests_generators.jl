@testset "Generators" begin

  @safetestset "New resource" begin
    using SearchLight

    SearchLight.Generator.newresource("Foo")

    @test isfile(joinpath("app", "resources", "foos", "Foos.jl")) == true

    @test isdir(joinpath("db", "migrations")) == true
    # @test occursin("_create_table_foos.jl", Base.Filesystem.readdir(joinpath("db", "migrations"))[1]) == true
    # @test length(SearchLight.Migrations.downed_migrations()) == 1


    @test isfile(joinpath("app", "resources", "foos", "FoosValidator.jl")) == true

    @test isfile(joinpath("test", "foos_test.jl")) == true


  end;

end;