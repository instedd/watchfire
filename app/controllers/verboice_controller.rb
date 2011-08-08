class VerboiceController < ApplicationController
  
  def plan
    # why do we need to force xml?
    self.formats = [:xml]
  end
  
  def callback
    puts "CALLLLLL BACK RECEIVEDDDD !!!!!"
  end

end
