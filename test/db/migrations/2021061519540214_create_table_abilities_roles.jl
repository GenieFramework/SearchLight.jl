module CreateTableAbilitiesRoles

import SearchLight.Migrations: create_table, column, primary_key, add_index, drop_table

function up()
  create_table(:abilitiesroles) do
    [
      primary_key()
      column(:abilities_id, :int)
      column(:roles_id, :int)
    ]
  end

  add_index(:abilitiesroles, :abilities_id)
  add_index(:abilitiesroles, :roles_id)
end

function down()
  drop_table(:abilitiesroles)
end

end
