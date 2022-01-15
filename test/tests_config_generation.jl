@safetestset "Create new config file" begin

#===============================================================================

  using SearchLight
  using YAML

  workdir = pwd()
  testdir = mktempdir()
  cd(testdir)

  @testset "Create config without explicit arguments" begin
    SearchLight.Generator.newconfig()
    @test isdir(joinpath(testdir, SearchLight.DB_PATH)) == true
    @test isfile(joinpath(testdir, SearchLight.DB_PATH, SearchLight.SEARCHLIGHT_DB_CONFIG_FILE_NAME)) == true
  end;

  @testset "Create config with custom file name" begin
    filename = "db.yml"
    SearchLight.Generator.newconfig(filename = filename)
    @test isfile(joinpath(testdir, SearchLight.DB_PATH, filename)) == true
  end;

  @testset "Create config with custom path and filename" begin
    filename = "db.yml"
    filepath = joinpath("foo", "bar", "baz")
    SearchLight.Generator.newconfig(filepath, filename = filename)
    @test isfile(joinpath(testdir, filepath, filename)) == true
  end;

  @testset "Create config in current dir" begin
    filename = "db.yml"
    filepath = "."
    SearchLight.Generator.newconfig(filepath, filename = filename)
    @test isfile(joinpath(testdir, filepath, filename)) == true
  end;

  cd(workdir)
end;

@safetestset "Adapter config properties" begin
  workdir = pwd()
  testdir = mktempdir()
  cd(testdir)

  @safetestset "Default adapter is MySQL" begin
    using SearchLight
    using YAML

    SearchLight.Generator.newconfig(".")
    db_conn_data = YAML.load(open(SearchLight.SEARCHLIGHT_DB_CONFIG_FILE_NAME))

    @test isa(db_conn_data, Dict) == true
    @test haskey(db_conn_data, SearchLight.config.app_env) == true
    @test haskey(db_conn_data[SearchLight.config.app_env], "adapter") == true
    @test db_conn_data[SearchLight.config.app_env]["adapter"] == "MySQL"
    @test haskey(db_conn_data[SearchLight.config.app_env], "port") == true
    @test db_conn_data[SearchLight.config.app_env]["port"] == 3306
  end;

  cd(workdir)

=#

end