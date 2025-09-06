require "test_helper"

class StaticControllerTest < ActionDispatch::IntegrationTest
  def setup
    @published_post = posts(:one)
    @draft_post = posts(:two)
  end

  # Index action tests
  test "should get index" do
    get root_path
    assert_response :success
  end

  test "should render index template" do
    get root_path
    assert_template "static/index"
    assert_template layout: "layouts/static"
  end

  test "should assign published posts ordered by published_at" do
    # Create posts with specific published dates to test ordering
    Post.delete_all
    old_post = Post.create!(
      title: "Old Post",
      body_md: "Content",
      status: :published,
      published_at: 2.days.ago
    )
    new_post = Post.create!(
      title: "New Post",
      body_md: "Content",
      status: :published,
      published_at: 1.day.ago
    )
    draft_post = Post.create!(
      title: "Draft Post",
      body_md: "Content",
      status: :draft
    )

    get root_path
    assert_response :success

    assigned_posts = assigns(:posts)
    assert_not_nil assigned_posts
    assert_equal 2, assigned_posts.count # Only published posts
    assert_equal new_post, assigned_posts.first # Newer post first
    assert_equal old_post, assigned_posts.second # Older post second
    assert_not_includes assigned_posts, draft_post # Draft not included
  end

  test "should handle empty posts list" do
    Post.delete_all
    get root_path
    assert_response :success

    assigned_posts = assigns(:posts)
    assert_not_nil assigned_posts
    assert_empty assigned_posts
  end

  # Post action tests
  test "should get published post by slug" do
    get post_path(@published_post.slug)
    assert_response :success
  end

  test "should render post template for published post" do
    get post_path(@published_post.slug)
    assert_template "static/post"
    assert_template layout: "layouts/static"
  end

  test "should assign correct post" do
    get post_path(@published_post.slug)
    assert_response :success

    assigned_post = assigns(:post)
    assert_not_nil assigned_post
    assert_equal @published_post, assigned_post
  end

  test "should return 404 for draft post" do
    get post_path(@draft_post.slug)
    # In test environment, Rails converts RecordNotFound to 404 status
    assert_response :not_found
  end

  test "should return 404 for non-existent slug" do
    get post_path("non-existent-slug")
    assert_response :not_found
  end

  # Error handling tests
  test "should handle post with nil published_at" do
    # Create published post with nil published_at
    post_with_nil_date = Post.create!(
      title: "Test Post",
      body_md: "Content",
      status: :published,
      published_at: nil
    )

    get post_path(post_with_nil_date.slug)
    assert_response :success
    assert_equal post_with_nil_date, assigns(:post)
  end

  # Security tests
  test "should only show published posts in index" do
    get root_path
    assigned_posts = assigns(:posts)

    assigned_posts.each do |post|
      assert post.published?, "Index should only contain published posts"
    end
  end

  test "should not allow access to draft posts via direct slug" do
    # Ensure we have a draft post
    draft = Post.create!(
      title: "Draft Post",
      body_md: "Secret content",
      status: :draft
    )

    get post_path(draft.slug)
    assert_response :not_found
  end

  # Performance/edge case tests
  test "should handle posts with special characters in slug" do
    special_post = Post.create!(
      title: "Post with Special & Characters!",
      body_md: "Content",
      status: :published
    )

    get post_path(special_post.slug)
    assert_response :success
    assert_equal special_post, assigns(:post)
  end

  test "should handle large number of published posts" do
    Post.delete_all

    # Create many published posts
    25.times do |i|
      Post.create!(
        title: "Post #{i}",
        body_md: "Content #{i}",
        status: :published,
        published_at: i.days.ago
      )
    end

    get root_path
    assert_response :success

    assigned_posts = assigns(:posts)
    assert_equal 25, assigned_posts.count
    # Should be ordered by published_at desc (newest first)
    assert assigned_posts.first.published_at > assigned_posts.last.published_at
  end
end
