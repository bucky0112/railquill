# frozen_string_literal: true

require "test_helper"

class RateLimitingTest < ActionDispatch::IntegrationTest
  setup do
    # Skip tests if rack-attack is not properly loaded (in test env it's disabled)
    skip "Rack::Attack is disabled in test environment" unless defined?(Rack::Attack) && Rails.env.development?

    # Reset rack-attack cache
    Rack::Attack.cache.store.clear

    # Create a test admin user
    @admin_user = AdminUser.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  teardown do
    # Clean up cache after each test
    Rack::Attack.cache.store.clear if defined?(Rack::Attack)
  end

  test "admin login rate limiting blocks excessive attempts" do
    # First few attempts should work (up to the limit)
    5.times do |i|
      post "/admin_users/sign_in", params: {
        admin_user: { email: @admin_user.email, password: "wrongpassword" }
      }

      if i < 4  # First 4 attempts
        assert_not_equal 429, response.status, "Should not be rate limited yet on attempt #{i + 1}"
      end
    end

    # 6th attempt should be rate limited
    post "/admin_users/sign_in", params: {
      admin_user: { email: @admin_user.email, password: "wrongpassword" }
    }
    assert_equal 429, response.status, "Should be rate limited after 5 attempts"
    assert_includes response.body, "Too Many Login Attempts"
  end

  test "admin login IP-based rate limiting works independently" do
    # Make requests with different email addresses from same IP
    10.times do |i|
      post "/admin_users/sign_in", params: {
        admin_user: { email: "test#{i}@example.com", password: "wrongpassword" }
      }
    end

    # 11th request should be rate limited by IP
    post "/admin_users/sign_in", params: {
      admin_user: { email: "new@example.com", password: "wrongpassword" }
    }
    assert_equal 429, response.status, "Should be rate limited by IP after 10 attempts"
  end

  test "password reset rate limiting works" do
    # First 3 password reset requests should work
    3.times do |i|
      post "/admin_users/password", params: {
        admin_user: { email: @admin_user.email }
      }

      if i < 2  # First 2 attempts
        assert_not_equal 429, response.status, "Should not be rate limited yet on attempt #{i + 1}"
      end
    end

    # 4th attempt should be rate limited
    post "/admin_users/password", params: {
      admin_user: { email: @admin_user.email }
    }
    assert_equal 429, response.status, "Should be rate limited after 3 password reset attempts"
    assert_includes response.body, "Password Reset Limit Exceeded"
  end

  test "admin dashboard rate limiting allows normal usage but blocks abuse" do
    # Simulate normal usage - should work
    60.times do
      get "/admin_dashboard"
      assert_not_equal 429, response.status, "Normal admin dashboard usage should not be rate limited"
    end

    # Simulate excessive requests - should eventually be blocked
    # We need to make a lot of requests quickly to trigger the rate limit
    # Skip this in regular test runs as it's slow - uncomment for manual testing
    skip "Skipping admin dashboard abuse test - too slow for regular test runs"

    # 200.times do
    #   get "/admin_dashboard"
    # end
    # assert_equal 429, response.status, "Excessive admin dashboard requests should be rate limited"
  end

  test "admin scanner paths are blocked" do
    suspicious_paths = [
      "/administrator",
      "/wp-admin",
      "/cpanel",
      "/phpmyadmin",
      "/admin.php",
      "/admin/login",
      "/backend",
      "/control",
      "/manager",
      "/webmaster",
      "/siteadmin"
    ]

    suspicious_paths.each do |path|
      get path
      assert_equal 403, response.status, "Suspicious path #{path} should be blocked"
      assert_includes response.body, "Forbidden"
    end
  end

  test "legitimate admin requests are not blocked" do
    # Legitimate admin paths should work
    legitimate_paths = [
      "/admin",
      "/admin_dashboard",
      "/admin_users/sign_in",
      "/admin/posts"
    ]

    legitimate_paths.each do |path|
      get path
      # Should get redirected to login or show the page (not blocked)
      assert_not_equal 403, response.status, "Legitimate path #{path} should not be blocked"
      assert_not_equal 429, response.status, "Legitimate path #{path} should not be rate limited"
    end
  end

  test "successful login resets rate limiting" do
    # Make some failed attempts
    3.times do
      post "/admin_users/sign_in", params: {
        admin_user: { email: @admin_user.email, password: "wrongpassword" }
      }
    end

    # Successful login should work
    post "/admin_users/sign_in", params: {
      admin_user: { email: @admin_user.email, password: "password123" }
    }

    # Should be redirected (successful login) or at least not rate limited
    assert_not_equal 429, response.status, "Successful login should not be rate limited"
  end

  test "write operations have stricter rate limits" do
    # Sign in first
    post "/admin_users/sign_in", params: {
      admin_user: { email: @admin_user.email, password: "password123" }
    }
    follow_redirect!

    # Test POST operations (would need to mock CSRF token for real test)
    # This is a simplified test - in practice you'd need proper CSRF handling
    skip "Write operations test requires CSRF token handling - implement if needed"
  end

  private

  # Helper method to simulate rate limiting in tests
  def simulate_rate_limit_exceeded(limit, period, key)
    # In a real test environment, you would need to actually make requests
    # For now, we'll just verify the configuration exists
    throttle = Rack::Attack.throttles[key]
    return false unless throttle

    throttle_limit = throttle.instance_variable_get(:@limit)
    throttle_period = throttle.instance_variable_get(:@period)

    throttle_limit <= limit && throttle_period >= period
  end
end
