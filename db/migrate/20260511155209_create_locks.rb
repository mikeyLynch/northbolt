class CreateLocks < ActiveRecord::Migration[8.0]
  def change
    create_table :locks do |t|
      t.references :location, null: false, foreign_key: true
      t.string :name, null: false
      t.datetime :last_seen_at

      t.timestamps
    end
  end
end
