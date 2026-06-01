class AddPermissionsToBusinessesAndUpdateRoles < ActiveRecord::Migration[8.1]
  DEFAULT_MATRIX = {
    "high"   => %w[manage_team manage_settings manage_api_keys manage_tenants grant_access revoke_access view_activity],
    "medium" => %w[manage_tenants grant_access revoke_access view_activity],
    "low"    => %w[grant_access view_activity]
  }.freeze

  def up
    add_column :businesses, :permission_matrix, :jsonb, null: false, default: DEFAULT_MATRIX

    # Backfill any businesses created before this migration
    Business.find_each { |b| b.update_columns(permission_matrix: DEFAULT_MATRIX) if b.permission_matrix.blank? }

    # Migrate existing member users to high
    execute "UPDATE users SET role = 'high' WHERE role = 'member'"
  end

  def down
    execute "UPDATE users SET role = 'member' WHERE role IN ('high', 'medium', 'low')"
    remove_column :businesses, :permission_matrix
  end
end
