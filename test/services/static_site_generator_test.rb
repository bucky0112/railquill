require "test_helper"

class StaticSiteGeneratorTest < ActiveSupport::TestCase
  def setup
    @generator = StaticSiteGenerator.new

    # Create test posts
    @published_post1 = Post.create!(
      title: "First Published Post",
      body_md: "## First Post

This is the **first** published post with [a link](http://example.com).",
      status: :published,
      published_at: 2.days.ago,
      excerpt: "This is the first published post",
      meta_description: "SEO description for first post",
      featured_image_url: "https://example.com/image1.jpg"
    )

    @published_post2 = Post.create!(
      title: "Second Published Post",
      body_md: "## Second Post

This is the second post.

```ruby
puts 'hello world'
```",
      status: :published,
      published_at: 1.day.ago,
      excerpt: "This is the second published post"
    )

    @draft_post = Post.create!(
      title: "Draft Post",
      body_md: "## Draft

This should not appear in static generation.",
      status: :draft
    )
  end

  # Basic functionality tests
  test "should initialize successfully" do
    assert_not_nil @generator
    assert_instance_of StaticSiteGenerator, @generator
  end

  # Index rendering tests
  test "should render index with published posts" do
    published_posts = Post.published_ordered
    html = @generator.render_index(published_posts)

    assert_not_nil html
    assert html.length > 0
    assert_includes html, @published_post1.title
    assert_includes html, @published_post2.title
    assert_not_includes html, @draft_post.title
  end

  test "should render index with empty posts collection" do
    html = @generator.render_index([])

    assert_not_nil html
    assert html.length > 0  # Should still render basic layout
  end

  test "should render index with post metadata" do
    published_posts = Post.published_ordered
    html = @generator.render_index(published_posts)

    # Check that post metadata is included (either full or abbreviated format)
    # Featured posts use full format ("%B %d, %Y"), grid posts use abbreviated ("%b %d, %Y")
    post1_full_date = @published_post1.published_at.strftime("%B %d, %Y")
    post1_abbrev_date = @published_post1.published_at.strftime("%b %d, %Y")
    post2_full_date = @published_post2.published_at.strftime("%B %d, %Y")
    post2_abbrev_date = @published_post2.published_at.strftime("%b %d, %Y")

    assert(html.include?(post1_full_date) || html.include?(post1_abbrev_date),
           "Expected to find either '#{post1_full_date}' or '#{post1_abbrev_date}' in rendered HTML")
    assert(html.include?(post2_full_date) || html.include?(post2_abbrev_date),
           "Expected to find either '#{post2_full_date}' or '#{post2_abbrev_date}' in rendered HTML")

    # Check reading time if present
    if @published_post1.reading_time.present?
      assert_includes html, "#{@published_post1.reading_time} min read"
    end
  end

  test "should render index with post excerpts" do
    published_posts = Post.published_ordered
    html = @generator.render_index(published_posts)

    assert_includes html, @published_post1.excerpt
    assert_includes html, @published_post2.excerpt
  end

  # Post rendering tests
  test "should render individual post" do
    html = @generator.render_post(@published_post1)

    assert_not_nil html
    assert html.length > 0
    assert_includes html, @published_post1.title

    # Should contain the post title as H1 (SEO best practice)
    assert_includes html, "<h1"

    # Should contain HTML-converted content from markdown
    assert_includes html, "<h2"  # Markdown ## converted to HTML <h2> (may have attributes)
  end

  test "should render post with markdown conversion" do
    html = @generator.render_post(@published_post1)

    # Should convert markdown to HTML
    assert_includes html, "<h2"  # ## becomes <h2> (may have attributes)
    assert_includes html, "<strong>"  # ** becomes <strong>
    assert_includes html, "<a href=\"http://example.com\""  # [link](url) becomes <a>

    # Should not include raw markdown
    assert_not_includes html, "## First Post"  # Raw markdown should be converted
    assert_not_includes html, "**first**"  # Raw markdown should be converted
  end

  test "should render post with code blocks" do
    html = @generator.render_post(@published_post2)

    # Should render code blocks properly
    assert_includes html, "<pre>"  # Code block should be in <pre>
    assert_includes html, "<code"  # With <code> inside
    assert_includes html, "puts"  # The actual code content
    # Content should be converted to HTML, not raw markdown
    assert_not_includes html, "```ruby"  # Raw code fence should be converted
  end

  test "should render post with all metadata" do
    html = @generator.render_post(@published_post1)

    # Check title in page
    assert_includes html, @published_post1.title

    # Check published date
    assert_includes html, @published_post1.published_at.strftime("%B %d, %Y")

    # Check reading time
    if @published_post1.reading_time.present?
      assert_includes html, "#{@published_post1.reading_time} min read"
    end

    # Check featured image if present
    if @published_post1.featured_image_url.present?
      assert_includes html, @published_post1.featured_image_url
    end
  end

  test "should render post with page title" do
    html = @generator.render_post(@published_post1)

    # Should include page title in the rendered HTML
    site_config = SiteConfig.instance
    expected_title = "#{@published_post1.title} - #{site_config.site_name}"
    assert_includes html, expected_title
  end

  test "should render post with navigation links" do
    html = @generator.render_post(@published_post1)

    # Should include navigation structure
    assert_includes html, "post-navigation"

    # Should include next/previous post links if they exist
    if @published_post1.next_post
      assert_includes html, @published_post1.next_post.title
    end

    if @published_post1.previous_post
      assert_includes html, @published_post1.previous_post.title
    end
  end

  test "should render post with sharing buttons" do
    html = @generator.render_post(@published_post1)

    # Should include social sharing buttons
    assert_includes html, "twitter.com/intent/tweet"
    assert_includes html, "linkedin.com/sharing"
    assert_includes html, "Share on Twitter"
    assert_includes html, "Share on LinkedIn"
  end

  # Error handling and edge cases
  test "should handle post with minimal content" do
    minimal_post = Post.create!(
      title: "Minimal Post",
      body_md: "Just text.",
      status: :published
    )

    html = @generator.render_post(minimal_post)

    assert_not_nil html
    assert_includes html, "Minimal Post"
    assert_includes html, "Just text."
  end

  test "should handle post with nil published_at" do
    post_without_date = Post.create!(
      title: "No Date Post",
      body_md: "Content",
      status: :published,
      published_at: nil
    )

    html = @generator.render_post(post_without_date)

    assert_not_nil html
    assert_includes html, "No Date Post"
    # Should use created_at instead of published_at
    assert_includes html, post_without_date.created_at.strftime("%B %d, %Y")
  end

  test "should handle post with special characters in markdown" do
    special_post = Post.create!(
      title: "Special & Characters",
      body_md: "Content with <script>alert('xss')</script> and & symbols.",
      status: :published
    )

    html = @generator.render_post(special_post)

    assert_not_nil html
    assert_includes html, "Special &amp; Characters"
    # Should sanitize HTML/script tags
    assert_not_includes html, "<script>"
    assert_not_includes html, "alert('xss')"
  end

  test "should handle post with long content" do
    long_content = "This is a very long post. " * 500  # Very long content
    long_post = Post.create!(
      title: "Long Post",
      body_md: long_content,
      status: :published
    )

    html = @generator.render_post(long_post)

    assert_not_nil html
    assert html.length > 1000  # Should render all content
    assert_includes html, "Long Post"
  end

  test "should handle minimal body_md gracefully" do
    minimal_post = Post.create!(
      title: "Minimal Post",
      body_md: "Just text.",  # Simple content to pass validation
      status: :published
    )

    html = @generator.render_post(minimal_post)

    assert_not_nil html
    assert_includes html, "Minimal Post"
    assert_includes html, "Just text."
    # Should not crash on simple content
  end

  # Template and layout tests
  test "should use static layout for both index and post" do
    published_posts = Post.published_ordered
    index_html = @generator.render_index(published_posts)
    post_html = @generator.render_post(@published_post1)

    # Both should use the static layout
    assert_includes index_html, "<!DOCTYPE html"  # Full HTML document
    assert_includes post_html, "<!DOCTYPE html"   # Full HTML document
  end

  test "should render with proper template structure" do
    published_posts = Post.published_ordered
    index_html = @generator.render_index(published_posts)

    # Should have proper HTML structure
    assert_includes index_html, "<html"
    assert_includes index_html, "<head>"
    assert_includes index_html, "<body"
    assert_includes index_html, "</html>"
  end

  # Performance tests
  test "should render large number of posts efficiently" do
    # Create many posts
    20.times do |i|
      Post.create!(
        title: "Post #{i}",
        body_md: "Content for post #{i}",
        status: :published,
        published_at: i.days.ago
      )
    end

    published_posts = Post.published_ordered

    start_time = Time.current
    html = @generator.render_index(published_posts)
    end_time = Time.current

    assert_not_nil html
    assert (end_time - start_time) < 10.seconds  # Should complete within 10 seconds
  end

  # Integration with helpers tests
  test "should provide markdown helper methods" do
    # Test the private markdown_to_html method
    html = @generator.send(:markdown_to_html, "**bold text**")

    assert_includes html, "<strong>bold text</strong>"
  end

  test "should handle nil markdown input" do
    html = @generator.send(:markdown_to_html, nil)

    assert_equal "", html
  end

  test "should handle empty markdown input" do
    html = @generator.send(:markdown_to_html, "")

    assert_equal "", html
  end

  # Markdown configuration tests
  test "should configure markdown renderer with security settings" do
    # Test security by trying to render potentially dangerous content
    dangerous_html = "<script>alert('xss')</script><p>Normal text</p>"
    safe_html = @generator.send(:markdown_to_html, dangerous_html)

    # Should filter out script tags but allow safe HTML
    assert_not_includes safe_html, "<script>"
    assert_not_includes safe_html, "alert('xss')"
    # May or may not include <p> depending on filter settings, so we test content is safe
    assert safe_html.length > 0
  end

  test "should enable useful markdown features" do
    test_markdown = <<~MD
      # Heading

      | Table | Header |
      |-------|--------|
      | Cell  | Data   |

      ~~strikethrough~~

      https://auto-link.com

      ```ruby
      code block
      ```
    MD

    html = @generator.send(:markdown_to_html, test_markdown)

    assert_includes html, "<h1 id=\"heading\">"  # Headers with ID
    assert_includes html, "<table>"  # Tables
    assert_includes html, "<del>"  # Strikethrough
    assert_includes html, "<a href=\"https://auto-link.com"  # Auto-links
    assert_includes html, "<code"  # Code blocks (may have class attribute)
  end
end
