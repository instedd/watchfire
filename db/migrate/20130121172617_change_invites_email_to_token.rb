class ChangeInvitesEmailToToken < ActiveRecord::Migration
  def self.up
    rename_column :invites, :email, :token
  end

  def self.down
    rename_column :invites, :token, :email
  end
end
