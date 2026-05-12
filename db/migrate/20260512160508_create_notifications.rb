class CreateNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :notifications do |t|
      t.references :business, null: false, foreign_key: true
      t.references :notifiable, polymorphic: true, null: true
      t.string :notification_type, null: false
      t.string :title, null: false
      t.text :body
      t.datetime :read_at

      t.timestamps
    end
  end
end
