class AddDeviceUuidToLocks < ActiveRecord::Migration[8.0]
  def change
    add_column :locks, :device_uuid, :string
    execute "UPDATE locks SET device_uuid = gen_random_uuid() WHERE device_uuid IS NULL"
    change_column_null :locks, :device_uuid, false
    add_index :locks, :device_uuid, unique: true
  end
end
