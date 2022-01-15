@testset "Core features" begin

  @safetestset "MySQL configuration" begin
    using SearchLight

    conn_info = SearchLight.Configuration.load("mysql_connection.yml")

    @test conn_info["adapter"] == "MySQL"
    @test conn_info["host"] == "127.0.0.1"
    @test conn_info["password"] == "root"
    @test conn_info["config"]["log_level"] == ":debug"
    @test conn_info["config"]["log_queries"] == true
    @test conn_info["port"] == 3306
    @test conn_info["username"] == "root"
    @test conn_info["database"] == "searchlight_tests"
  end;

end