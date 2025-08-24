class StaticSiteGenerator
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::SanitizeHelper
  
  def initialize
    @markdown = Redcarpet::Markdown.new(
      Redcarpet::Render::HTML.new(
        filter_html: false,  # Allow HTML tags like iframe
        no_images: false,
        no_links: false,
        no_styles: false,    # Allow style attributes for iframe
        safe_links_only: true,
        with_toc_data: true
      ),
      autolink: true,
      tables: true,
      fenced_code_blocks: true,
      lax_spacing: true,
      no_intra_emphasis: true,
      strikethrough: true,
      superscript: true
    )
  end
  
  def render_index(posts)
    @posts = posts
    @site_config = SiteConfig.instance
    ApplicationController.render(
      template: 'static/index',
      layout: 'static',
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
      template: 'static/post',
      layout: 'static',
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
      template: 'static/about',
      layout: 'static',
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
      template: 'static/archive',
      layout: 'static',
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
    return "" if text.blank?
    @markdown.render(text)
  end
end