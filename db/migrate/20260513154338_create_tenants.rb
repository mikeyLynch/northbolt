class CreateTenants < ActiveRecord::Migration[8.0]
  def change
    create_table :tenants do |t|
      t.references :business, null: false, foreign_key: true
      t.string :first_name, null: false
      t.string :last_name,  null: false
      t.string :email,      null: false
      t.string :phone,      null: false

      t.timestamps
    end

    add_index :tenants, [ :business_id, :email ], unique: true
  end
end
