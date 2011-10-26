module VolunteersHelper
  
  def sort_header name, order
    selected = @order == order.to_s
    dir_class = @direction == 'DESC' ? 'down' : 'up'
    url = url_for :action => :index, :order => order, :page => @page, :direction => selected ? invert(@direction) : 'ASC', :q => @q
    content_tag :th, :class => "link sort #{dir_class if selected}", 'data-url' => url do
      concat name
      concat content_tag :span
    end
  end
  
  def import_errors_for(object)
    if object.errors.any?
      content_tag :div, :class => "import_error_description error_description" do
        content_tag :ul do
          raw object.errors.full_messages.map { |msg| content_tag(:li, msg) }.join
        end
      end
    end
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
