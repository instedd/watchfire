module VolunteersHelper
  
  def sort_link name, order
    link_to name, :action => :index, :order => order, :page => @page, :direction => @order == order.to_s ? 'DESC' : 'ASC'
  end
  
end
