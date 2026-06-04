class AddBillingDetailsToBusinesses < ActiveRecord::Migration[8.1]
  def change
    add_column :businesses, :billing_details, :jsonb, null: false, default: {}
  end
end
