module CreateTableAbilities

import SearchLight.Migrations: create_table, column, primary_key, add_index, drop_table

function up()
  create_table(:abilities) do
    [
      primary_key()
      column(:name, :string, limit = 100)
    ]
  end

  add_index(:abilities, :name)
end

function down()
  drop_table(:abilities)
end

end
