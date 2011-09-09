module ApplicationHelper
  
  def section title, url, name
    raw "<li class=\"#{controller_name == name.to_s ? "active" : ""}\">#{link_to title, url}</li>"
  end
  
  def breadcrumb
    raw render_breadcrumbs :builder => BreadcrumbBuilder
  end
  
end
