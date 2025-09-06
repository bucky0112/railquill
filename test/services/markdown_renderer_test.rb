require "test_helper"

class MarkdownRendererTest < ActiveSupport::TestCase
  # Basic Markdown functionality tests
  test "should render basic markdown elements" do
    markdown = <<~MD
      # Heading 1
      ## Heading 2

      **Bold text** and *italic text*

      - List item 1
      - List item 2

      [Link](https://example.com)
    MD

    html = MarkdownRenderer.render(markdown)

    assert_includes html, '<h1 id="heading-1">Heading 1</h1>'
    assert_includes html, '<h2 id="heading-2">Heading 2</h2>'
    assert_includes html, "<strong>Bold text</strong>"
    assert_includes html, "<em>italic text</em>"
    assert_includes html, "<li>List item 1</li>"
    assert_includes html, '<a href="https://example.com">Link</a>'
  end

  test "should render code blocks with syntax highlighting classes" do
    markdown = <<~MD
      ```ruby
      def hello
        puts "world"
      end
      ```

      Inline `code` here.
    MD

    html = MarkdownRenderer.render(markdown)

    assert_includes html, "<pre>"
    assert_includes html, "<code"
    assert_includes html, "def hello"
    assert_includes html, "<code>code</code>"
  end

  test "should render tables" do
    markdown = <<~MD
      | Header 1 | Header 2 |
      |----------|----------|
      | Cell 1   | Cell 2   |
    MD

    html = MarkdownRenderer.render(markdown)

    assert_includes html, "<table>"
    assert_includes html, "<thead>"
    assert_includes html, "<tbody>"
    assert_includes html, "<th>Header 1</th>"
    assert_includes html, "<td>Cell 1</td>"
  end

  # XSS Protection Tests
  test "should remove script tags completely" do
    dangerous_markdown = <<~MD
      # Heading

      <script>alert('XSS')</script>

      Normal content here.

      <script src="malicious.js"></script>
    MD

    html = MarkdownRenderer.render(dangerous_markdown)

    assert_not_includes html, "<script>"
    assert_not_includes html, "</script>"
    assert_not_includes html, "alert("
    assert_not_includes html, "malicious.js"
    assert_includes html, '<h1 id="heading">Heading</h1>'
    assert_includes html, "Normal content here."
  end

  test "should remove style tags and inline styles" do
    dangerous_markdown = <<~MD
      <style>body { display: none; }</style>

      <p style="color: red;">Styled paragraph</p>

      Normal content.
    MD

    html = MarkdownRenderer.render(dangerous_markdown)

    assert_not_includes html, "<style>"
    assert_not_includes html, "</style>"
    assert_not_includes html, "display: none"
    assert_not_includes html, "style="
    assert_includes html, "Styled paragraph"
    assert_includes html, "Normal content."
  end

  test "should remove javascript event handlers" do
    dangerous_markdown = <<~MD
      <p onclick="alert('XSS')">Click me</p>

      <img onload="steal_cookies()" src="image.jpg">

      <a href="javascript:alert('XSS')">Bad link</a>
    MD

    html = MarkdownRenderer.render(dangerous_markdown)

    assert_not_includes html, "onclick="
    assert_not_includes html, "onload="
    assert_not_includes html, "javascript:"
    assert_not_includes html, "alert("
    assert_not_includes html, "steal_cookies"
    assert_includes html, "Click me"
  end

  test "should remove dangerous iframe and object tags" do
    dangerous_markdown = <<~MD
      <iframe src="javascript:alert('XSS')"></iframe>

      <object data="malicious.swf"></object>

      <embed src="malicious.swf">

      Normal content.
    MD

    html = MarkdownRenderer.render(dangerous_markdown)

    assert_not_includes html, "<iframe"
    assert_not_includes html, "<object"
    assert_not_includes html, "<embed"
    assert_includes html, "Normal content."
  end

  test "should allow safe links but block dangerous protocols" do
    markdown = <<~MD
      [HTTP Link](http://example.com)
      [HTTPS Link](https://secure.com)
      [Email](mailto:test@example.com)
      [Relative](#section)
      [JavaScript](javascript:alert('XSS'))
      [Data URI](data:text/html,<script>alert('XSS')</script>)
    MD

    html = MarkdownRenderer.render(markdown)

    assert_includes html, 'href="http://example.com"'
    assert_includes html, 'href="https://secure.com"'
    assert_includes html, 'href="mailto:test@example.com"'
    assert_not_includes html, "javascript:"
    # Data URIs in links should be blocked, but may be allowed for images
    assert_not_includes html, 'href="data:'
  end

  test "should allow safe images" do
    markdown = <<~MD
      ![Alt text](https://example.com/image.jpg "Title")
      ![HTTP image](http://example.com/image.png)
    MD

    html = MarkdownRenderer.render(markdown)

    assert_includes html, "<img"
    assert_includes html, 'src="https://example.com/image.jpg"'
    assert_includes html, 'src="http://example.com/image.png"'
    assert_includes html, 'alt="Alt text"'
    assert_includes html, 'title="Title"'
  end

  test "should preserve syntax highlighting class attributes" do
    markdown = <<~MD
      ```ruby
      puts "Hello, World!"
      ```

      ```javascript#{'  '}
      console.log("Hello");
      ```
    MD

    html = MarkdownRenderer.render(markdown)

    # Should preserve code classes for syntax highlighting
    assert_includes html, "<code"
    # Rouge adds language-specific classes
    assert html.include?("class=") || html.include?("language-")
  end

  test "should handle mixed safe and dangerous content" do
    mixed_markdown = <<~MD
      # Safe Heading

      This is **safe** content.

      <script>alert('dangerous')</script>

      More safe content with [a link](https://example.com).

      <style>body { background: red; }</style>

      ```ruby
      # Safe code block
      puts "Hello"
      ```

      <p onclick="danger()">Paragraph with event</p>

      Final safe paragraph.
    MD

    html = MarkdownRenderer.render(mixed_markdown)

    # Safe content should remain
    assert_includes html, '<h1 id="safe-heading">Safe Heading</h1>'
    assert_includes html, "<strong>safe</strong>"
    assert_includes html, "More safe content"
    assert_includes html, 'href="https://example.com"'
    assert_includes html, 'puts "Hello"'
    assert_includes html, "Final safe paragraph"

    # Dangerous content should be removed
    assert_not_includes html, "<script>"
    assert_not_includes html, "alert("
    assert_not_includes html, "<style>"
    assert_not_includes html, "background: red"
    assert_not_includes html, "onclick="
    assert_not_includes html, "danger()"

    # But text content should be preserved (without dangerous attributes)
    assert_includes html, "Paragraph with event"
  end

  # Edge cases
  test "should handle empty input" do
    assert_equal "", MarkdownRenderer.render("")
    assert_equal "", MarkdownRenderer.render(nil)
    assert_equal "", MarkdownRenderer.render("   ")
  end

  test "should handle malformed HTML gracefully" do
    malformed_markdown = <<~MD
      # Heading

      <script>alert('test')</script>

      Normal content after script.
    MD

    html = MarkdownRenderer.render(malformed_markdown)

    # Should not crash and should still sanitize
    assert_not_includes html, "<script>"
    assert_not_includes html, "alert("
    assert_includes html, "Normal content after script"
  end

  test "should preserve heading IDs for table of contents" do
    markdown = <<~MD
      # First Heading
      ## Second Heading#{'  '}
      ### Third Heading with Spaces
    MD

    html = MarkdownRenderer.render(markdown)

    assert_includes html, 'id="first-heading"'
    assert_includes html, 'id="second-heading"'
    assert_includes html, 'id="third-heading-with-spaces"'
  end
end
