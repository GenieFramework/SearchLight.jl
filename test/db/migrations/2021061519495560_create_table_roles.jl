module CreateTableRoles

import SearchLight.Migrations: create_table, column, primary_key, add_index, drop_table

function up()
  create_table(:roles) do
    [
      primary_key()
      column(:name, :string, limit = 100)
    ]
  end

  add_index(:roles, :name)
end

function down()
  drop_table(:roles)
end

end
