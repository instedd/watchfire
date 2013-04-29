class PigeonChannel < ActiveRecord::Base
  belongs_to :organization

  has_many :current_calls, :dependent => :destroy

  enum_attr :channel_type, %w(^verboice nuntium)

  attr_accessible :description, :name, :enabled

  validates_presence_of :organization, :name, :pigeon_name
  validates_presence_of :channel_type

  scope :enabled, where(:enabled => true)
  scope :nuntium, where(:channel_type => :nuntium)
  scope :verboice, where(:channel_type => :verboice)

  before_save :prepare_advice
  after_commit :advice_scheduler

  def verboice?
    channel_type == :verboice
  end

  def nuntium?
    channel_type == :nuntium
  end

  alias_method :voice?, :verboice?
  alias_method :sms?, :nuntium?

  def has_slots_available?
    current_calls.count < limit
  end

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

