class RemoveStaffFromUsers < ActiveRecord::Migration[8.1]
  def change
    remove_column :users, :staff, :boolean, default: false, null: false
  end
end
