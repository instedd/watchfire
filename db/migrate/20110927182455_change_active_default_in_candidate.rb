class ChangeActiveDefaultInCandidate < ActiveRecord::Migration
  def self.up
    change_column_default :candidates, :active, true
  end

  def self.down
    change_column_default :candidates, :active, nil
  end
end
