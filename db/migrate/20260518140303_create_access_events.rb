class CreateAccessEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :access_events do |t|
      t.references :lock, null: false, foreign_key: true
      t.string   :event_type,  null: false
      t.datetime :occurred_at, null: false
      t.datetime :created_at,  null: false
    end

    add_index :access_events, [ :lock_id, :occurred_at ]
  end
end
