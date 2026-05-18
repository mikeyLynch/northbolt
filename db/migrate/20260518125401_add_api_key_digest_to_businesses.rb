class AddApiKeyDigestToBusinesses < ActiveRecord::Migration[8.1]
  def change
    add_column :businesses, :api_key_digest, :string
  end
end
