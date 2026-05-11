class CreateLocations < ActiveRecord::Migration[8.0]
  def change
    create_table :locations do |t|
      t.references :business, null: false, foreign_key: true
      t.string :name, null: false
      t.string :address_line_1
      t.string :address_line_2
      t.string :city
      t.string :postcode
      t.string :country

      t.timestamps
    end
  end
end
