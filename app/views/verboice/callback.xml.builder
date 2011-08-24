xml.instruct!
xml.Response do
  xml.Say I18n.t(:voice_successful)
  xml.Hangup
end