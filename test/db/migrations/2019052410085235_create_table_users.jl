module CreateTableUsers

import SearchLight.Migrations: create_table, column, primary_key, add_index, drop_table

function up()
  create_table(:users) do
    [
      primary_key()
      column(:username, :string, limit = 100)
      column(:password, :string, limit = 100)
      column(:name, :string, limit = 100)
      column(:email, :string, limit = 100)
    ]
  end

  add_index(:users, :username)
end

function down()
  drop_table(:users)
end

end