class PreviewsController < ApplicationController
  before_action :authenticate_admin_user!
  before_action :load_site_config

  def show
    @post = Post.find_by!(slug: params[:slug])
    render "static/post", layout: "static"
  end

  private

  def load_site_config
    @site_config = SiteConfig.instance
  end
end
