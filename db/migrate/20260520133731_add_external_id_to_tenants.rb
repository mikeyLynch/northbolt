class AddExternalIdToTenants < ActiveRecord::Migration[8.1]
  def change
    add_column :tenants, :external_id, :string
    add_index  :tenants, [ :business_id, :external_id ], unique: true
  end
end
