class StaticController < ApplicationController
  layout 'static'
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
      format.xml { render content_type: 'application/rss+xml' }
    end
  end
  
  def static_file
    static_file_path = Rails.root.join("static_site", "#{params[:slug]}.html")
    
    if File.exist?(static_file_path)
      send_file static_file_path, type: 'text/html', disposition: 'inline'
    else
      raise ActionController::RoutingError, "Static file not found"
    end
  end
  
  private
  
  def load_site_config
    @site_config = SiteConfig.instance
  end
end