class AddBillingFieldsToBusinesses < ActiveRecord::Migration[8.1]
  def change
    add_column :businesses, :vat_number, :string
  end
end
