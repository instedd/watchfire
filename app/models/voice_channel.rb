class VoiceChannel < Channel
  belongs_to :volunteer, :inverse_of => :voice_channels
end
