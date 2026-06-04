class CreateInvoiceLineItems < ActiveRecord::Migration[8.1]
  def change
    create_table :invoice_line_items do |t|
      t.references :invoice, null: false, foreign_key: true
      t.string  :description,     null: false
      t.decimal :quantity,        null: false, default: 1, precision: 10, scale: 2
      t.integer :unit_price_pence, null: false
      t.integer :total_pence,     null: false
      t.timestamps
    end
  end
end
