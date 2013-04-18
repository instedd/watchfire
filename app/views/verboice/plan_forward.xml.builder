xml.instruct!
xml.Response do
  if @mission
    xml.Dial({:channel => @channel, :callerId => @from}, @mission.forward_address)
  end
  xml.Hangup
end
