require "test_helper"

class PreviewsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin_user = admin_users(:one)
    @published_post = posts(:one)
    @draft_post = posts(:two)
  end

  # Authentication tests
  test "should redirect to login when not authenticated" do
    get preview_path(@published_post.slug)
    assert_redirected_to new_admin_user_session_path
  end

  test "should allow access when authenticated as admin" do
    sign_in @admin_user
    get preview_path(@published_post.slug)
    assert_response :success
  end

  # Functionality tests for authenticated users
  test "should show published post in preview" do
    sign_in @admin_user
    get preview_path(@published_post.slug)

    assert_response :success
    assert_template "static/post"
    assert_template layout: "layouts/static"
    assert_equal @published_post, assigns(:post)
  end

  test "should show draft post in preview" do
    sign_in @admin_user
    get preview_path(@draft_post.slug)

    assert_response :success
    assert_template "static/post"
    assert_template layout: "layouts/static"
    assert_equal @draft_post, assigns(:post)
  end

  test "should find post by slug regardless of status" do
    sign_in @admin_user

    # Test both published and draft posts
    [ "published", "draft" ].each do |status|
      post = Post.create!(
        title: "Test #{status.capitalize} Post",
        body_md: "Content for #{status} post",
        status: status
      )

      get preview_path(post.slug)
      assert_response :success
      assert_equal post, assigns(:post)
    end
  end

  # Error handling tests
  test "should return 404 for non-existent post when authenticated" do
    sign_in @admin_user

    get preview_path("non-existent-slug")
    assert_response :not_found
  end

  test "should handle special characters in slug" do
    sign_in @admin_user

    special_post = Post.create!(
      title: "Post with Special & Characters!",
      body_md: "Content",
      status: :draft
    )

    get preview_path(special_post.slug)
    assert_response :success
    assert_equal special_post, assigns(:post)
  end

  # Security tests
  test "should not bypass authentication with invalid session" do
    # Simulate invalid/expired session
    get preview_path(@published_post.slug), headers: { "Cookie" => "invalid_session=invalid_value" }
    assert_redirected_to new_admin_user_session_path
  end

  test "should maintain authentication across different preview requests" do
    sign_in @admin_user

    # Make multiple preview requests
    get preview_path(@published_post.slug)
    assert_response :success

    get preview_path(@draft_post.slug)
    assert_response :success
  end

  # Integration with static layout tests
  test "should use static layout for preview" do
    sign_in @admin_user
    get preview_path(@published_post.slug)

    assert_response :success
    assert_template layout: "layouts/static"
    # Should look exactly like the public static version
    assert_template "static/post"
  end

  test "should render preview with all post data" do
    sign_in @admin_user

    # Create post with all fields populated
    full_post = Post.create!(
      title: "Complete Post",
      body_md: "# Heading\n\nParagraph with **bold** text.",
      excerpt: "Custom excerpt",
      meta_description: "SEO description",
      featured_image_url: "https://example.com/image.jpg",
      status: :draft
    )

    get preview_path(full_post.slug)
    assert_response :success

    assigned_post = assigns(:post)
    assert_equal full_post.title, assigned_post.title
    assert_equal full_post.body_md, assigned_post.body_md
    assert_equal full_post.excerpt, assigned_post.excerpt
    assert_equal full_post.meta_description, assigned_post.meta_description
    assert_equal full_post.featured_image_url, assigned_post.featured_image_url
  end

  # Performance tests
  test "should handle preview of large posts efficiently" do
    sign_in @admin_user

    large_content = "Lorem ipsum " * 1000  # Create large content
    large_post = Post.create!(
      title: "Large Post",
      body_md: large_content,
      status: :draft
    )

    start_time = Time.current
    get preview_path(large_post.slug)
    end_time = Time.current

    assert_response :success
    # Should complete in reasonable time (< 5 seconds)
    assert (end_time - start_time) < 5.seconds
  end
end
