require 'xmpp4r/client'

module XmppHelper
  include Jabber
  def answer_call
    @xmpp_messages = []
    @xmpp_client = Client.new 'testingstg@gmail.com'
    @xmpp_client.connect 'talk.google.com', 5222
    @xmpp_client.auth '8c4mmha2'
    @xmpp_client.send Presence.new.set_show(:chat)
    @xmpp_client.add_message_callback do |msg|
      #p msg.from
      #p msg.body
      @xmpp_messages << msg
    end
    #send_xmpp "login #{login} #{password}"
  end

  def reply(message)
    msg = Message.new
    msg.to = 'manas.watchfire@gmail.com'
    msg.body = message
    msg.type = :chat

    @xmpp_client.send msg
  end

  def xmpp_user_should_receive(body)
    unless has_xmpp_message?(body)
      sleep 30
      unless has_xmpp_message?(body)
        ::RSpec::Expectations.fail_with(%Q(Expected to receive '#{body}' via xmpp but didn't. Messages received: #{@xmpp_messages.map{|msg| msg.body}.join "\n"}))
      end
    end
  end

  def clear_xmpp_messages
    sleep 15
    @xmpp_messages.clear
  end

  def has_xmpp_message?(body)
    @xmpp_messages.any?{|msg| msg.from.bare.to_s == 'geochat-stg@instedd.org' && msg.body == body}
  end
end
