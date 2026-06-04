class CreateRefunds < ActiveRecord::Migration[8.1]
  def change
    create_table :refunds do |t|
      t.references :invoice, null: false, foreign_key: true
      t.integer :amount_pence, null: false
      t.text    :reason,       null: false
      t.datetime :issued_at,   null: false
      t.timestamps
    end
  end
end
