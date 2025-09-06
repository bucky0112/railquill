require "sanitize"

class MarkdownRenderer
  def self.render(text)
    return "" if text.blank?

    @markdown ||= Redcarpet::Markdown.new(
      Redcarpet::Render::HTML.new(
        filter_html: false,  # We'll handle sanitization after rendering
        no_images: false,
        no_links: false,
        no_styles: false,
        safe_links_only: false,  # We'll validate links in sanitization
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

    # Apply proper HTML sanitization to prevent XSS while allowing safe blog content
    sanitized_html = Sanitize.fragment(html, sanitization_config)

    sanitized_html
  end

  private

  def self.sanitization_config
    {
      elements: %w[
        h1 h2 h3 h4 h5 h6
        p br
        strong b em i u s del ins mark
        ul ol li
        blockquote
        pre code
        table thead tbody tr th td
        a
        img
        hr
        div span
        sup sub
      ],

      attributes: {
        "a" => %w[href title],
        "img" => %w[src alt title width height],
        "code" => %w[class],  # Allow class for syntax highlighting
        "pre" => %w[class],   # Allow class for syntax highlighting
        "h1" => %w[id],       # Allow id for TOC links
        "h2" => %w[id],       # Allow id for TOC links
        "h3" => %w[id],       # Allow id for TOC links
        "h4" => %w[id],       # Allow id for TOC links
        "h5" => %w[id],       # Allow id for TOC links
        "h6" => %w[id],       # Allow id for TOC links
        "th" => %w[align],    # Allow table alignment
        "td" => %w[align],    # Allow table alignment
        "div" => %w[class],   # Allow div classes for styling
        "span" => %w[class]   # Allow span classes for styling
      },

      protocols: {
        "a" => { "href" => %w[http https mailto] },
        "img" => { "src" => %w[http https data] }  # Allow data URIs for small images
      },

      remove_contents: %w[script style],
      remove_empty_elements: false,
      whitespace_elements: {
        "div" => :remove,
        "p" => :remove,
        "pre" => :keep
      }
    }
  end
end
