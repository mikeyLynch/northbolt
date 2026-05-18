class AddPublicKeyToLocks < ActiveRecord::Migration[8.1]
  def change
    add_column :locks, :public_key, :text
  end
end
