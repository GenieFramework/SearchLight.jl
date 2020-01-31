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

  @safetestset "MySQL connection" begin
    using SearchLight

    conn_info = SearchLight.Configuration.load("mysql_connection.yml")
    conn = SearchLight.connect()

    @test conn.host == "127.0.0.1"
    @test conn.port == "3306"
    @test conn.db == "searchlight_tests"
    @test conn.user == "root"
  end;

  @safetestset "MySQL query" begin
    using SearchLight

    conn_info = SearchLight.Configuration.load("mysql_connection.yml")
    conn = SearchLight.connect()

    @test isempty(SearchLight.query("SHOW TABLES")) == true
    @test SearchLight.Migration.create_migrations_table() == true
    @test Array(SearchLight.query("SHOW TABLES")) == SearchLight.config.db_migrations_table_name
  end;
end