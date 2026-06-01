class AddRoleToInvitations < ActiveRecord::Migration[8.1]
  def change
    add_column :invitations, :role, :string, null: false, default: "medium"
  end
end
