class AddStoraWebhookFieldsToBusinesses < ActiveRecord::Migration[8.1]
  def change
    add_column :businesses, :stora_webhook_token, :string
    add_column :businesses, :stora_webhook_secret, :string
    add_index  :businesses, :stora_webhook_token, unique: true
  end
end
