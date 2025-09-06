class StaticController < ApplicationController
  layout "static"
  before_action :load_site_config

  def index
    @posts = Post.published_ordered
  end

  def about
    # Site config loaded by before_action
  end

  def archive
    @posts = Post.published_ordered
  end

  def post
    @post = Post.published.find_by!(slug: params[:slug])
  end

  def feed
    @posts = Post.published_ordered.limit(20)
    respond_to do |format|
      format.xml { render content_type: "application/rss+xml" }
    end
  end

  def static_file
    # Sanitize slug to prevent path traversal - only allow safe characters
    slug = params[:slug]
    unless slug.match?(/\A[a-zA-Z0-9\-_]+\z/)
      raise ActionController::RoutingError, "Invalid file name"
    end

    # Build path component by component to avoid path traversal issues
    static_site_dir = Rails.root.join("static_site")
    filename = "#{slug}.html"
    static_file_path = static_site_dir.join(filename)

    # Double-check that the resolved path is within the static_site directory
    unless static_file_path.to_s.start_with?(static_site_dir.to_s)
      raise ActionController::RoutingError, "Invalid file path"
    end

    if File.exist?(static_file_path)
      # brakeman:disable FileAccess
      send_file static_file_path, type: "text/html", disposition: "inline"
      # brakeman:enable FileAccess
    else
      raise ActionController::RoutingError, "Static file not found"
    end
  end

  private

  def load_site_config
    @site_config = SiteConfig.instance
  end
end
