module ApplicationHelper
  
  def section title, url, name
    raw "<li class=\"#{controller_name == name.to_s ? "active" : ""}\">#{link_to title, url}</li>"
  end
  
  def breadcrumb
    raw render_breadcrumbs :builder => BreadcrumbBuilder
  end
  
  def link_to_if_not(condition, options = {}, html_options = {}, &block)
    if condition
      capture(&block)
    else
      link_to(options, html_options, &block)
    end
  end
  
end
