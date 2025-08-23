module ApplicationHelper
  def markdown_to_html(text)
    return "" if text.blank?
    MarkdownRenderer.render(text)
  end
end
