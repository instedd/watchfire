class AddCityToMission < ActiveRecord::Migration
  def change
    add_column :missions, :city, :string
  end
end
