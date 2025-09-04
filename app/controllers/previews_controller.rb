class PreviewsController < ApplicationController
  before_action :authenticate_admin_user!

  def show
    @post = Post.find_by!(slug: params[:slug])
    render "static/post", layout: "static"
  end
end
