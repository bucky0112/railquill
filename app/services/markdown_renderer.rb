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

    @markdown.render(text)
  end
end
