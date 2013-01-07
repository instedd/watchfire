class AddCallSettingsToOrganizations < ActiveRecord::Migration
  def self.up
    add_column :organizations, :max_sms_retries, :integer, :default => 3
    add_column :organizations, :max_voice_retries, :integer, :default => 3
    add_column :organizations, :sms_timeout, :integer, :default => 5
    add_column :organizations, :voice_timeout, :integer, :default => 5
  end

  def self.down
    remove_column :organizations, :max_sms_retries, :integer
    remove_column :organizations, :max_voice_retries, :integer
    remove_column :organizations, :sms_timeout, :integer
    remove_column :organizations, :voice_timeout, :integer
  end
end
