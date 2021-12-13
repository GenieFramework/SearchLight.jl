module CreateTableFoos

import SearchLight.Migrations: create_table, column, columns, primary_key, add_index, drop_table, add_indices

function up()
  create_table(:foos) do
    [
      primary_key()
      column(:column_name, :column_type)
      columns([
        :column_name => :column_type
      ])
    ]
  end

  add_index(:foos, :column_name)
  add_indices(foos, :column_name_1, :column_name_2)
end

function down()
  drop_table(:foos)
end

end
