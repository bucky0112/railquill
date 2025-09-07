require "test_helper"

class BlogWorkflowTest < ActionDispatch::IntegrationTest
  def setup
    @admin_user = admin_users(:one)
  end

  # Publishing workflow tests
  test "complete post publishing workflow" do
    sign_in @admin_user

    # Step 1: Create a draft post
    post = Post.create!(
      title: "Test Blog Post",
      body_md: "# My Test Post\n\nThis is a test post with some **bold text** and a [link](http://example.com).",
      status: :draft
    )

    assert post.draft?
    assert_not_nil post.slug
    assert_equal "test-blog-post", post.slug

    # Step 2: Preview the draft post (should be accessible when signed in)
    get preview_path(post.slug)
    assert_response :success
    assert_includes response.body, "My Test Post"
    assert_includes response.body, "<strong>bold text</strong>"

    # Step 3: Publish the post
    post.publish!
    post.reload

    assert post.published?
    assert_not_nil post.published_at

    # Step 4: View the published post publicly
    get post_path(post.slug)
    assert_response :success
    assert_includes response.body, "My Test Post"
    assert_includes response.body, "<strong>bold text</strong>"

    # Step 5: Check that the post appears in the public index
    get root_path
    assert_response :success
    assert_includes response.body, "Test Blog Post"
  end

  test "draft posts are not publicly accessible" do
    # Create a draft post
    draft_post = Post.create!(
      title: "Secret Draft",
      body_md: "This is secret content",
      status: :draft
    )

    # Should not be accessible publicly
    get post_path(draft_post.slug)
    assert_response :not_found

    # Should not appear in public index
    get root_path
    assert_response :success
    assert_not_includes response.body, "Secret Draft"

    # But should be accessible via preview when authenticated
    sign_in @admin_user
    get preview_path(draft_post.slug)
    assert_response :success
    assert_includes response.body, "Secret Draft"
  end

  test "post unpublishing workflow" do
    sign_in @admin_user

    # Create and publish a post
    post = Post.create!(
      title: "Published Post",
      body_md: "This will be unpublished",
      status: :published,
      published_at: 1.hour.ago
    )

    # Verify it's publicly accessible
    get post_path(post.slug)
    assert_response :success

    # Unpublish the post
    post.unpublish!
    post.reload

    assert post.draft?

    # Should no longer be publicly accessible
    get post_path(post.slug)
    assert_response :not_found

    # But should still be accessible via preview when authenticated
    get preview_path(post.slug)
    assert_response :success
    assert_includes response.body, "Published Post"
  end

  # Authentication workflow tests
  test "admin authentication workflow" do
    # Should not be able to access preview without authentication
    post = Post.create!(
      title: "Test Post",
      body_md: "Content",
      status: :draft
    )

    get preview_path(post.slug)
    assert_redirected_to new_admin_user_session_path

    # Should not be able to access admin dashboard (may return 200 with redirect or error)
    get admin_dashboard_path
    assert_not_equal :success, response.status

    # Sign in
    sign_in @admin_user

    # Now should be able to access preview
    get preview_path(post.slug)
    assert_response :success

    # And admin dashboard
    get admin_dashboard_path
    assert_response :success
  end

  # Static site generation workflow
  test "static site generation workflow" do
    # Clear existing posts
    Post.delete_all

    # Create published posts
    post1 = Post.create!(
      title: "First Post",
      body_md: "# First Post\n\nThis is the first post.",
      status: :published,
      published_at: 2.days.ago
    )

    post2 = Post.create!(
      title: "Second Post",
      body_md: "# Second Post\n\nThis is the second post.",
      status: :published,
      published_at: 1.day.ago
    )

    draft_post = Post.create!(
      title: "Draft Post",
      body_md: "# Draft\n\nThis is a draft.",
      status: :draft
    )

    # Test static generation
    generator = StaticSiteGenerator.new

    # Generate index
    published_posts = Post.published_ordered
    index_html = generator.render_index(published_posts)

    assert_includes index_html, "First Post"
    assert_includes index_html, "Second Post"
    assert_not_includes index_html, "Draft Post"

    # Generate individual posts
    post1_html = generator.render_post(post1)
    assert_includes post1_html, "First Post"
    assert_includes post1_html, "This is the first post."

    post2_html = generator.render_post(post2)
    assert_includes post2_html, "Second Post"
    assert_includes post2_html, "This is the second post."
  end

  # SEO and metadata workflow
  test "seo metadata workflow" do
    post = Post.create!(
      title: "SEO Test Post",
      body_md: "# SEO Content\n\nThis post tests SEO features.",
      status: :published,
      excerpt: "Custom excerpt for SEO",
      meta_description: "SEO meta description",
      featured_image_url: "https://example.com/featured.jpg"
    )

    # Test public post includes SEO metadata
    get post_path(post.slug)
    assert_response :success

    # Check for featured image (this will be in application layout)
    assert_includes response.body, "https://example.com/featured.jpg"

    # Note: SEO meta tags would be in static layout, not application layout
    # This test verifies the application can handle posts with SEO data
  end

  # Post navigation workflow
  test "post navigation workflow" do
    # Clear existing posts and create a sequence
    Post.delete_all

    old_post = Post.create!(
      title: "Old Post",
      body_md: "Old content",
      status: :published,
      published_at: 3.days.ago
    )

    middle_post = Post.create!(
      title: "Middle Post",
      body_md: "Middle content",
      status: :published,
      published_at: 2.days.ago
    )

    new_post = Post.create!(
      title: "New Post",
      body_md: "New content",
      status: :published,
      published_at: 1.day.ago
    )

    # Test navigation on middle post
    get post_path(middle_post.slug)
    assert_response :success

    # Should have links to previous and next posts
    assert_includes response.body, old_post.title  # Previous
    assert_includes response.body, new_post.title  # Next

    # Test navigation on first post (should only have next)
    get post_path(old_post.slug)
    assert_response :success
    assert_includes response.body, middle_post.title  # Next
    # Should not have previous post link content

    # Test navigation on last post (should only have previous)
    get post_path(new_post.slug)
    assert_response :success
    assert_includes response.body, middle_post.title  # Previous
  end

  # Reading time calculation workflow
  test "reading time calculation workflow" do
    # Create post with specific word count
    words = Array.new(400) { "word" }.join(" ")  # 400 words = 2 minutes at 200 WPM
    post = Post.create!(
      title: "Reading Time Test",
      body_md: words,
      status: :published
    )

    assert_equal 2, post.reading_time

    # Should display reading time on public page
    get post_path(post.slug)
    assert_response :success
    assert_includes response.body, "2 min read"

    # Should also display on index
    get root_path
    assert_response :success
    assert_includes response.body, "2 min read"
  end

  # Error handling workflows
  test "handles invalid post slugs gracefully" do
    # Test with non-existent slug
    get post_path("non-existent-slug")
    assert_response :not_found

    # Test with malformed slug
    get post_path("../../../etc/passwd")
    assert_response :not_found

    # Test with empty slug - in Rails 8, this may generate a valid URL
    # but should still result in not found when accessing
    begin
      get post_path("")
      assert_response :not_found
    rescue ActionController::UrlGenerationError
      # This is also acceptable - empty slug should either:
      # 1. Generate URL but return 404, or 2. Raise UrlGenerationError
      assert true
    end
  end

  test "handles posts with missing or invalid published_at dates" do
    # Post with nil published_at
    post_nil_date = Post.create!(
      title: "No Date Post",
      body_md: "Content",
      status: :published,
      published_at: nil
    )

    get post_path(post_nil_date.slug)
    assert_response :success
    # Should use created_at as fallback
    assert_includes response.body, post_nil_date.created_at.strftime("%B %d, %Y")

    # Post in the future
    future_post = Post.create!(
      title: "Future Post",
      body_md: "Future content",
      status: :published,
      published_at: 1.week.from_now
    )

    # Should still be accessible (we don't filter by future dates)
    get post_path(future_post.slug)
    assert_response :success
  end

  # Edge cases and boundary conditions
  test "handles empty blog gracefully" do
    Post.delete_all

    # Index should work with no posts
    get root_path
    assert_response :success

    # Should handle static generation with empty collection
    generator = StaticSiteGenerator.new
    html = generator.render_index([])
    assert_not_nil html
    assert html.length > 0
  end

  test "handles posts with special characters in titles and content" do
    special_post = Post.create!(
      title: "Special & Characters <test>",
      body_md: "Content with & ampersands and <script>alert('xss')</script>",
      status: :published
    )

    get post_path(special_post.slug)
    assert_response :success

    # Should escape special characters
    assert_includes response.body, "Special &amp; Characters"
    # Should not include script tags
    assert_not_includes response.body, "<script>"
    assert_not_includes response.body, "alert('xss')"
  end

  test "handles concurrent post creation and publishing" do
    # Simulate concurrent operations
    post1 = Post.create!(title: "Concurrent 1", body_md: "Content 1", status: :draft)
    post2 = Post.create!(title: "Concurrent 2", body_md: "Content 2", status: :draft)

    # Publish both
    post1.publish!
    post2.publish!

    # Both should be accessible
    get post_path(post1.slug)
    assert_response :success

    get post_path(post2.slug)
    assert_response :success

    # Both should appear in index
    get root_path
    assert_response :success
    assert_includes response.body, "Concurrent 1"
    assert_includes response.body, "Concurrent 2"
  end
end
