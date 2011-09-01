class Day
  
  @@days = [:sunday, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday]
  @@order = [1, 2, 3, 4, 5, 6, 0]
  
  class << self
    
    def all
      @@days
    end
    
    def at time
      time.strftime('%A').downcase.to_sym
    end
    
    def method_missing(method, *args, &block)
      if @@days.include?(method)
        method
      else
        raise NoMethodError
      end
    end
    
  end
  
end