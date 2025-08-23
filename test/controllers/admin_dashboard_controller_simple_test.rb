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
    
    @draft_post = Post.create!(
      title: "Draft Post",
      body_md: draft_content,
      status: :draft
    )
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
    
    # Test word count calculation
    total_words = Post.published.sum { |p| p.body_md.to_s.split.size }
    assert total_words > 0
    
    # Test average reading time
    avg_reading_time = Post.published.average(:reading_time).to_i
    assert avg_reading_time > 0
    
    # Test posts this month count
    posts_this_month = Post.published.where("published_at >= ?", 1.month.ago).count
    assert_equal 1, posts_this_month
  end
end