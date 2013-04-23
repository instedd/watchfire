class PigeonChannel < ActiveRecord::Base
  belongs_to :organization

  enum_attr :channel_type, %w(^verboice nuntium)

  attr_accessible :description, :name, :enabled

  validates_presence_of :organization, :name, :pigeon_name
  validates_presence_of :channel_type

  scope :enabled, where(:enabled => true)
  scope :nuntium, where(:channel_type => :nuntium)
  scope :verboice, where(:channel_type => :verboice)

  before_save :prepare_advice
  after_commit :advice_scheduler

private

  def prepare_advice
    @should_advice = enabled && (new_record? || !enabled_was)
    true
  end

  def advice_scheduler
    if @should_advice
      SchedulerAdvisor.channel_enabled self
    end
    true
  end
end

