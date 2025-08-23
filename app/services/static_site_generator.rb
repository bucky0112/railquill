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
    ApplicationController.render(
      template: 'static/index',
      layout: 'static',
      assigns: { posts: @posts },
      locals: { 
        markdown_to_html: method(:markdown_to_html),
        strip_tags: method(:strip_tags),
        truncate: method(:truncate)
      }
    )
  end
  
  def render_post(post)
    ApplicationController.render(
      template: 'static/post',
      layout: 'static',
      assigns: { 
        post: post,
        page_title: "#{post.title} - My Blog"
      },
      locals: { 
        markdown_to_html: method(:markdown_to_html)
      }
    )
  end
  
  private
  
  def markdown_to_html(text)
    return "" if text.blank?
    @markdown.render(text)
  end
end