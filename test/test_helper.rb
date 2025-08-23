ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...

    # Helper methods for creating test posts
    def create_published_post(title: "Test Post", body_md: "Test content", **attributes)
      Post.create!({
        title: title,
        body_md: body_md,
        status: :published,
        published_at: 1.day.ago
      }.merge(attributes))
    end

    def create_draft_post(title: "Draft Post", body_md: "Draft content", **attributes)
      Post.create!({
        title: title,
        body_md: body_md,
        status: :draft
      }.merge(attributes))
    end

    def create_post_with_content(word_count: 200)
      # Create post with specific word count for reading time testing
      words = Array.new(word_count) { "word" }.join(" ")
      create_published_post(body_md: words)
    end

    def create_test_admin_user(email: "test@example.com", password: "password123")
      AdminUser.create!(email: email, password: password, password_confirmation: password)
    end

    # Helper methods for assertions
    def assert_post_published(post)
      assert post.published?, "Expected post to be published, but was #{post.status}"
      assert_not_nil post.published_at, "Expected published post to have published_at set"
    end

    def assert_post_draft(post)
      assert post.draft?, "Expected post to be draft, but was #{post.status}"
    end

    def assert_valid_slug(post)
      assert_not_nil post.slug, "Expected post to have a slug"
      assert post.slug.present?, "Expected slug to be present"
      assert_match /\A[a-z0-9\-]+\z/, post.slug, "Expected slug to contain only lowercase letters, numbers, and hyphens"
    end

    def assert_reading_time_calculated(post)
      assert_not_nil post.reading_time, "Expected post to have reading_time calculated"
      assert post.reading_time > 0, "Expected reading_time to be positive"
    end

    # Helper for testing markdown rendering
    def assert_markdown_rendered(html_content, original_markdown)
      # Check that common markdown elements are converted
      if original_markdown.include?("**")
        assert_includes html_content, "<strong>", "Expected bold markdown to be converted"
      end
      if original_markdown.include?("# ")
        assert_includes html_content, "<h1", "Expected heading markdown to be converted"
      end
      if original_markdown.include?("[")
        assert_includes html_content, "<a ", "Expected link markdown to be converted"
      end
    end

    # Helper for cleaning up test data
    def cleanup_test_posts
      Post.delete_all
    end

    def cleanup_test_admin_users
      AdminUser.where.not(id: admin_users.map(&:id)).delete_all
    end
  end
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
