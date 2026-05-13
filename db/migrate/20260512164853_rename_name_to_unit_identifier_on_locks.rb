class RenameNameToUnitIdentifierOnLocks < ActiveRecord::Migration[8.0]
  def change
    rename_column :locks, :name, :unit_identifier
  end
end
