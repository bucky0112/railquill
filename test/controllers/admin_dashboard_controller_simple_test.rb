require "test_helper"

class AdminDashboardControllerSimpleTest < ActionDispatch::IntegrationTest
  def setup
    @admin_user = admin_users(:one)

    # Create clean test data
    Post.delete_all
    # Create posts with enough content to get predictable reading times
    published_content = "This is published content with enough words to get a meaningful reading time calculation. " * 20  # About 200 words = 1 minute
    draft_content = "This is draft content. " * 10  # About 50 words = 1 minute (rounded up)

    @published_post = Post.create!(
      title: "Published Post",
      body_md: published_content,
      status: :published,
      published_at: 1.day.ago
    )
    # Ensure word count is calculated (should happen automatically via callback)
    @published_post.reload

    @draft_post = Post.create!(
      title: "Draft Post",
      body_md: draft_content,
      status: :draft
    )
    # Ensure word count is calculated (should happen automatically via callback)
    @draft_post.reload
  end

  test "controller instance variables are set correctly when accessed directly" do
    sign_in @admin_user

    # Test the controller action directly
    controller = AdminDashboardController.new
    controller.request = ActionDispatch::Request.new({})
    controller.send(:index)

    # Check instance variables are set
    assert_equal 2, controller.instance_variable_get(:@total_posts)
    assert_equal 1, controller.instance_variable_get(:@published_posts)
    assert_equal 1, controller.instance_variable_get(:@draft_posts)
    # Reading time will be auto-calculated based on content length
    total_reading_time = controller.instance_variable_get(:@total_reading_time)
    assert total_reading_time > 0

    recent_posts = controller.instance_variable_get(:@recent_posts)
    assert_equal 2, recent_posts.count
  end

  test "metrics calculations work correctly" do
    # Test the actual logic without the HTTP layer
    assert_equal 2, Post.count
    assert_equal 1, Post.published.count
    assert_equal 1, Post.draft.count
    # Reading time is auto-calculated, so just verify it's positive
    published_reading_time = Post.published.sum(:reading_time)
    assert published_reading_time > 0

    # Test optimized word count calculation (database-level)
    total_words = Post.published.sum(:word_count) || 0
    assert total_words > 0

    # Verify word count is properly stored for each post
    Post.published.each do |post|
      assert post.word_count > 0, "Post #{post.title} should have word_count calculated"
      # Verify stored word count matches calculated value
      expected_word_count = post.body_md.to_s.split.size
      assert_equal expected_word_count, post.word_count, "Word count should match calculated value"
    end

    # Test average reading time
    avg_reading_time = Post.published.average(:reading_time).to_i
    assert avg_reading_time > 0

    # Test posts this month count
    posts_this_month = Post.published.where("published_at >= ?", 1.month.ago).count
    assert_equal 1, posts_this_month
  end

  test "word count calculation is performant" do
    # Create additional posts to test performance
    10.times do |i|
      Post.create!(
        title: "Performance Test #{i}",
        body_md: "Content with multiple words for testing. " * 50,
        status: :published,
        published_at: 1.day.ago
      )
    end

    # Measure performance of the optimized query
    require "benchmark"
    time_taken = Benchmark.realtime do
      50.times do
        Post.published.sum(:word_count) || 0
      end
    end

    # Should be very fast - under 100ms for 50 queries even with extra data
    assert time_taken < 0.1, "Word count calculation should be fast: #{time_taken}s"

    # Verify we get the correct result
    total_words = Post.published.sum(:word_count) || 0
    assert total_words > 0, "Should have calculated total words"
  end
end
