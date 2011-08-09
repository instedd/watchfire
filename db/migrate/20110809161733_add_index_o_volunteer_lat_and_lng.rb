class AddIndexOVolunteerLatAndLng < ActiveRecord::Migration
  def self.up
		add_index  :volunteers, [:lat, :lng]
  end

  def self.down
		remove_index  :volunteers, [:lat, :lng]
  end
end
