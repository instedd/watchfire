class AddForwardAddressToMission < ActiveRecord::Migration
  def change
    add_column :missions, :forward_address, :string
  end
end
