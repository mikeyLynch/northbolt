class RenameAccessGrantsPinDigestToPinCiphertext < ActiveRecord::Migration[8.1]
  def change
    rename_column :access_grants, :pin_digest, :pin_ciphertext
  end
end
