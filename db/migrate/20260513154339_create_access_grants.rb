class CreateAccessGrants < ActiveRecord::Migration[8.0]
  def change
    create_table :access_grants do |t|
      t.references :lock,   null: false, foreign_key: true
      t.references :tenant, null: false, foreign_key: true
      t.string   :pin_digest, null: false
      t.datetime :starts_at,  null: false
      t.datetime :ends_at,    null: false
      t.datetime :revoked_at

      t.timestamps
    end

    add_index :access_grants, [ :lock_id, :revoked_at ]
  end
end
