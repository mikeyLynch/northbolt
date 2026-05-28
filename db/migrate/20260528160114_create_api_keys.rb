class CreateApiKeys < ActiveRecord::Migration[8.1]
  def change
    create_table :api_keys do |t|
      t.references :business, null: false, foreign_key: true
      t.string   :name,        null: false
      t.string   :digest,      null: false
      t.datetime :last_used_at
      t.datetime :revoked_at

      t.timestamps
    end

    remove_column :businesses, :api_key_digest, :string
  end
end
