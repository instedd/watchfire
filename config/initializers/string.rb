class String
	def with_protocol
    "sms://#{self}"
  end
end