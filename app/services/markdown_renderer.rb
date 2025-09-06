class MarkdownRenderer
  def self.render(text)
    return "" if text.blank?

    @markdown ||= Redcarpet::Markdown.new(
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

    html = @markdown.render(text)
    
    # Apply XSS protection - remove dangerous script and style tags but allow other HTML
    # This maintains compatibility with iframe embeds while preventing XSS attacks
    html.gsub!(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/mi, '')
    html.gsub!(/<style\b[^<]*(?:(?!<\/style>)<[^<]*)*<\/style>/mi, '')
    html.gsub!(/<script[^>]*>/i, '')
    html.gsub!(/<\/script>/i, '')
    
    html
  end
end
