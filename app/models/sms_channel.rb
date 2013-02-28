class SmsChannel < Channel
  belongs_to :volunteer, :inverse_of => :sms_channels
end
