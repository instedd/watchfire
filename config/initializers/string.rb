class String
  def with_protocol
    "sms://#{self}"
  end

  def sentences
    self.split('.').map(&:strip).reject{|s| s.blank?}
  end

  def to_sentence
    "#{self.strip_sentence}. "
  end

  def strip_sentence
    s = self.strip
    s.chomp!('.') if s.end_with?('.')
    s.strip
  end
end
