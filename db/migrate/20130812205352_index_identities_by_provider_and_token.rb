class IndexIdentitiesByProviderAndToken < ActiveRecord::Migration
  def up
    add_index :identities, [:provider, :token]
  end

  def down
    remove_index :identities, [:provider, :token]
  end
end
