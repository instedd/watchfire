class PigeonChannel < ActiveRecord::Base
  belongs_to :organization

  enum_attr :channel_type, %w(^verboice nuntium)

  attr_accessible :description, :name

  validates_presence_of :organization, :name, :pigeon_name
  validates_presence_of :channel_type

  before_destroy :unlink_missions

  scope :verboice, where(:channel_type => :verboice).order(:name)
  scope :nuntium, where(:channel_type => :nuntium).order(:name)

  def missions
    Mission.where(['verboice_channel_id = :id OR nuntium_channel_id = :id', id: id])
  end

  private

  def unlink_missions
    if missions.where(:status => :running).count > 0
      errors.add :base, "Cannot delete channel while there are missions using it"
    else
      missions.each do |mission|
        mission.unlink_channel! self
      end
    end
    errors.empty?
  end
end

