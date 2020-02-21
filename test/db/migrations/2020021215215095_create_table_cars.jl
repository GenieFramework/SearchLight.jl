module CreateTableCars

import SearchLight.Migrations: create_table, column, primary_key, add_index, drop_table

function up()
  create_table(:cars) do
    [
      primary_key()
      column(:column_name, :column_type)
    ]
  end

  add_index(:cars, :column_name)
end

function down()
  drop_table(:cars)
end

end
