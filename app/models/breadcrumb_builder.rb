class BreadcrumbBuilder < BreadcrumbsOnRails::Breadcrumbs::Builder

  def render
    "<ul class='breadcrumb'>#{@elements.map{|e| item(e)}.join}</ul>"
  end

  def item element
    if @context.current_page?(compute_path(element))
      @context.content_tag(:li, :class => "active") do
        @context.content_tag(:span, "") + @context.html_escape(compute_name(element)) 
      end
    else
      @context.content_tag :li do
        @context.link_to(@context.html_escape(compute_name(element)), compute_path(element))
      end
    end
  end

end
