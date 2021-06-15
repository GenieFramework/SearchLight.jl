module CreateTableRolesUsers

import SearchLight.Migrations: create_table, column, primary_key, add_index, drop_table

function up()
  create_table(:rolesusers) do
    [
      primary_key()
      column(:roles_id, :int)
      column(:users_id, :int)
    ]
  end

  add_index(:rolesusers, :roles_id)
  add_index(:rolesusers, :users_id)
end

function down()
  drop_table(:rolesusers)
end

end
