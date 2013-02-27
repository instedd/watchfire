module ApplicationHelper
  def current_organization
    current_user.current_organization
  end

  def section title, url, name
    raw "<li class=\"#{controller_name == name.to_s ? "active" : ""}\">#{link_to title, url}</li>"
  end

  def breadcrumb
    raw render_breadcrumbs :builder => BreadcrumbBuilder
  end

  def watchfire_version
    begin
      @@watchfire_version = File.read('REVISION').strip unless defined? @@watchfire_version
    rescue Errno::ENOENT
      @@watchfire_version = 'Development'
    end
    @@watchfire_version
  end

  def platform_base_url
    @@platform_base_url ||= Watchfire::Application.config.platform_base_url
  end

  def platform_url path = ''
    URI::join(platform_base_url, path).to_s
  end
end
