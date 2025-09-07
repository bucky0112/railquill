require "test_helper"

class PostTest < ActiveSupport::TestCase
  # Setup for tests
  def setup
    @published_post = posts(:one)
    @draft_post = posts(:two)
  end

  # Validation tests
  test "should require title" do
    post = Post.new(body_md: "Some content", slug: "test-slug")
    assert_not post.valid?
    assert_includes post.errors[:title], "can't be blank"
  end

  test "should require body_md" do
    post = Post.new(title: "Test Title", slug: "test-slug")
    assert_not post.valid?
    assert_includes post.errors[:body_md], "can't be blank"
  end

  test "should auto-generate slug from title" do
    post = Post.new(title: "Test Title", body_md: "Some content")
    assert post.valid?
    assert_equal "test-title", post.slug
  end

  test "should validate slug presence when bypassing generation" do
    post = Post.new(title: nil, body_md: "Some content", slug: "")
    assert_not post.valid?
    assert_includes post.errors[:slug], "can't be blank"
  end

  test "should require unique slug" do
    # Clear all posts to ensure clean test
    Post.delete_all

    existing_post = Post.create!(title: "Same Title", body_md: "Content")
    duplicate_post = Post.new(title: "Same Title", body_md: "Different content")
    # Both posts will have same slug due to same title
    assert_not duplicate_post.valid?
    assert_includes duplicate_post.errors[:slug], "has already been taken"
  end

  # Enum tests
  test "should have draft and published statuses" do
    assert_equal 0, Post.statuses[:draft]
    assert_equal 1, Post.statuses[:published]
  end

  test "should allow setting draft status" do
    post = Post.new(title: "Test", body_md: "Content", status: :draft)
    assert post.draft?
  end

  # Callback tests
  test "should generate slug from title before validation" do
    post = Post.new(title: "My Amazing Post", body_md: "Content")
    post.valid?
    assert_equal "my-amazing-post", post.slug
  end

  test "should update slug when title changes" do
    post = Post.create!(title: "Original Title", body_md: "Content")
    original_slug = post.slug
    post.title = "New Title"
    post.valid?
    assert_not_equal original_slug, post.slug
    assert_equal "new-title", post.slug
  end

  test "should not regenerate slug if title unchanged" do
    post = Post.create!(title: "Title", body_md: "Content")
    original_slug = post.slug
    post.body_md = "New content"
    post.valid?
    assert_equal original_slug, post.slug
  end

  test "should calculate reading time before save" do
    # 200 words should take 1 minute
    words = Array.new(200) { "word" }.join(" ")
    post = Post.create!(title: "Test", body_md: words)
    assert_equal 1, post.reading_time
  end

  test "should calculate reading time for longer content" do
    # 600 words should take 3 minutes (600/200 = 3)
    words = Array.new(600) { "word" }.join(" ")
    post = Post.create!(title: "Test", body_md: words)
    assert_equal 3, post.reading_time
  end

  test "should round up reading time" do
    # 250 words should take 2 minutes (250/200 = 1.25, rounded up to 2)
    words = Array.new(250) { "word" }.join(" ")
    post = Post.create!(title: "Test", body_md: words)
    assert_equal 2, post.reading_time
  end

  test "should generate excerpt if blank" do
    long_content = "This is a very long piece of content that should be truncated to create an excerpt. " * 5
    post = Post.create!(title: "Test", body_md: long_content)
    assert_not_nil post.excerpt
    assert post.excerpt.length <= 160
  end

  test "should not overwrite existing excerpt" do
    existing_excerpt = "Custom excerpt"
    post = Post.create!(title: "Test", body_md: "Long content", excerpt: existing_excerpt)
    assert_equal existing_excerpt, post.excerpt
  end

  test "should strip markdown from excerpt" do
    markdown_content = "# Heading\n\n**Bold text** and *italic text* with [link](url)"
    post = Post.create!(title: "Test", body_md: markdown_content)
    assert_not_includes post.excerpt, "#"
    assert_not_includes post.excerpt, "**"
    assert_not_includes post.excerpt, "*"
    assert_not_includes post.excerpt, "["
    assert_not_includes post.excerpt, "]"
    assert_not_includes post.excerpt, "("
    assert_not_includes post.excerpt, ")"
  end

  # Scope tests
  test "published scope should only return published posts" do
    published_posts = Post.published
    assert_includes published_posts, @published_post
    assert_not_includes published_posts, @draft_post
  end

  test "published_ordered scope should order by published_at desc" do
    # Create posts with different published_at times
    old_post = Post.create!(title: "Old", body_md: "Content", status: :published, published_at: 2.days.ago)
    new_post = Post.create!(title: "New", body_md: "Content", status: :published, published_at: 1.day.ago)

    ordered_posts = Post.published_ordered
    assert_equal new_post, ordered_posts.first
    assert ordered_posts.index(new_post) < ordered_posts.index(old_post)
  end

  # Instance method tests
  test "to_param should return slug" do
    assert_equal @published_post.slug, @published_post.to_param
  end

  test "publish! should set status to published and published_at" do
    travel_to Time.current do
      @draft_post.publish!
      @draft_post.reload
      assert @draft_post.published?
      assert_not_nil @draft_post.published_at
      assert_in_delta Time.current, @draft_post.published_at, 1.second
    end
  end

  test "publish! should not change existing published_at" do
    existing_time = 1.week.ago
    @draft_post.update!(published_at: existing_time)
    @draft_post.publish!
    @draft_post.reload
    assert_equal existing_time.to_i, @draft_post.published_at.to_i
  end

  test "unpublish! should set status to draft" do
    @published_post.unpublish!
    @published_post.reload
    assert @published_post.draft?
  end

  test "next_post should return next published post chronologically" do
    # Clear existing data that might interfere
    Post.delete_all

    old_post = Post.create!(title: "Old", body_md: "Content", status: :published, published_at: 2.days.ago)
    middle_post = Post.create!(title: "Middle", body_md: "Content", status: :published, published_at: 1.day.ago)
    new_post = Post.create!(title: "New", body_md: "Content", status: :published, published_at: Time.current)

    assert_equal middle_post, old_post.next_post
    assert_equal new_post, middle_post.next_post
    assert_nil new_post.next_post
  end

  test "previous_post should return previous published post chronologically" do
    # Clear existing data that might interfere
    Post.delete_all

    old_post = Post.create!(title: "Old", body_md: "Content", status: :published, published_at: 2.days.ago)
    middle_post = Post.create!(title: "Middle", body_md: "Content", status: :published, published_at: 1.day.ago)
    new_post = Post.create!(title: "New", body_md: "Content", status: :published, published_at: Time.current)

    assert_nil old_post.previous_post
    assert_equal old_post, middle_post.previous_post
    assert_equal middle_post, new_post.previous_post
  end

  test "next_post and previous_post should only consider published posts" do
    # Clear existing data that might interfere
    Post.delete_all

    old_published = Post.create!(title: "Old Published", body_md: "Content", status: :published, published_at: 2.days.ago)
    draft_middle = Post.create!(title: "Draft Middle", body_md: "Content", status: :draft, published_at: 1.day.ago)
    new_published = Post.create!(title: "New Published", body_md: "Content", status: :published, published_at: Time.current)

    assert_equal new_published, old_published.next_post
    assert_equal old_published, new_published.previous_post
  end

  # Edge cases and error conditions
  test "should handle empty body_md for reading time calculation" do
    post = Post.new(title: "Test", body_md: "", slug: "test")
    post.send(:calculate_reading_time)
    assert_nil post.reading_time
  end

  test "should handle nil body_md for excerpt generation" do
    post = Post.new(title: "Test", body_md: nil, slug: "test")
    post.send(:generate_excerpt)
    assert_nil post.excerpt
  end

  test "should handle special characters in title for slug generation" do
    post = Post.new(title: "Test & Title with 'Special' Characters!")
    post.send(:generate_slug)
    assert_equal "test-title-with-special-characters", post.slug
  end

  test "should handle empty title for slug generation" do
    post = Post.new(title: "")
    post.send(:generate_slug)
    # Empty title results in nil slug
    assert_nil post.slug
  end

  test "should handle nil title for slug generation" do
    post = Post.new(title: nil)
    post.send(:generate_slug)
    # Nil title results in nil slug
    assert_nil post.slug
  end

  # Ransack configuration tests
  test "should define ransackable attributes" do
    expected_attributes = [ "body_md", "created_at", "excerpt", "featured_image_alt", "featured_image_url", "id", "meta_description", "published_at", "reading_time", "slug", "status", "title", "updated_at", "word_count" ]
    assert_equal expected_attributes, Post.ransackable_attributes
  end

  test "should define empty ransackable associations" do
    assert_equal [], Post.ransackable_associations
  end
end
