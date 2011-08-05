class NuntiumController < ApplicationController
  
  def receive
    puts params[:body]
    render :nothing => true
  end

end
