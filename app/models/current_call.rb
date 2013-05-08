class CurrentCall < ActiveRecord::Base
  belongs_to :pigeon_channel
  belongs_to :candidate
  attr_accessible :call_status, :session_id, :voice_number

  validates_presence_of :pigeon_channel
  validates_presence_of :candidate

  validate :is_voice_channel

  def timeout
    self.fail
  end

  def fail
  end

private

  def is_voice_channel
    unless pigeon_channel.voice?
      errors[:pigeon_channel] << "must be a voice channel"
    end
  end
end
