# frozen_string_literal: true

class SitemapController < ApplicationController
  before_action :set_format

  def index
    @site_config = SiteConfig.instance
    @posts = Post.published.published_ordered
    @last_modified = [ @posts.maximum(:updated_at), @site_config.updated_at ].compact.max

    respond_to do |format|
      format.xml { render layout: false }
    end
  end

  private

  def set_format
    request.format = :xml
  end
end
