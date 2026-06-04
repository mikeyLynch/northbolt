class CreateInvoices < ActiveRecord::Migration[8.1]
  def change
    create_table :invoices do |t|
      t.references :business, null: false, foreign_key: true
      t.string  :number,               null: false
      t.string  :category,             null: false
      t.string  :installment
      t.string  :status,               null: false, default: "draft"
      t.integer :subtotal_pence,       null: false, default: 0
      t.string  :discount_type
      t.decimal :discount_value,       precision: 10, scale: 2
      t.integer :discount_amount_pence, default: 0
      t.decimal :vat_rate,             null: false, default: 0.20, precision: 5, scale: 4
      t.integer :vat_pence,            null: false, default: 0
      t.integer :total_pence,          null: false, default: 0
      t.date    :issued_at
      t.date    :due_at
      t.datetime :paid_at
      t.date    :service_period_start
      t.date    :service_period_end
      t.text    :notes
      t.timestamps
    end

    add_index :invoices, :number, unique: true
    add_index :invoices, [ :business_id, :status ]
  end
end
