class StaticSiteGenerator
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::SanitizeHelper

  def initialize
    # No longer need local markdown renderer - use centralized MarkdownRenderer service
  end

  def render_index(posts)
    @posts = posts
    @site_config = SiteConfig.instance
    ApplicationController.render(
      template: "static/index",
      layout: "static",
      assigns: {
        posts: @posts,
        site_config: @site_config,
        page_title: @site_config.site_name
      },
      locals: {
        markdown_to_html: method(:markdown_to_html),
        strip_tags: method(:strip_tags),
        truncate: method(:truncate)
      }
    )
  end

  def render_post(post)
    @site_config = SiteConfig.instance
    ApplicationController.render(
      template: "static/post",
      layout: "static",
      assigns: {
        post: post,
        site_config: @site_config,
        page_title: "#{post.title} - #{@site_config.site_name}"
      },
      locals: {
        markdown_to_html: method(:markdown_to_html)
      }
    )
  end

  def render_about
    @site_config = SiteConfig.instance
    ApplicationController.render(
      template: "static/about",
      layout: "static",
      assigns: {
        site_config: @site_config,
        page_title: "About #{@site_config.site_name}"
      },
      locals: {
        markdown_to_html: method(:markdown_to_html)
      }
    )
  end

  def render_archive(posts)
    @site_config = SiteConfig.instance
    ApplicationController.render(
      template: "static/archive",
      layout: "static",
      assigns: {
        posts: posts,
        site_config: @site_config,
        page_title: "Archive - #{@site_config.site_name}"
      },
      locals: {
        markdown_to_html: method(:markdown_to_html),
        strip_tags: method(:strip_tags),
        truncate: method(:truncate)
      }
    )
  end

  private

  def markdown_to_html(text)
    # Delegate to the secure MarkdownRenderer service
    MarkdownRenderer.render(text)
  end
end
