module VolunteersHelper
  
  def sort_header name, order
    selected = @order == order.to_s
    dir_class = @direction == 'DESC' ? 'down' : 'up'
    url = url_for :action => :index, :order => order, :page => @page, :direction => selected ? invert(@direction) : 'ASC'
    content_tag :th, :class => "link sort #{dir_class if selected}", 'data-url' => url do
      concat name
      concat content_tag :span
    end
  end
  
  def disabled_check_box
    check_box_tag "", "", false, :disabled => "disabled"
  end
  
  private
  
  def invert order
    case order
    when 'DESC'
      'ASC'
    else
      'DESC'
    end
  end
  
end
