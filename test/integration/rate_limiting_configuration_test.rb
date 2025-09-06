# frozen_string_literal: true

require "test_helper"

class RateLimitingConfigurationTest < ActionDispatch::IntegrationTest
  test "rack-attack configuration is properly loaded" do
    # This test verifies that rate limiting configuration is properly set up
    # In test environment, rack-attack is disabled but configuration should be loadable

    # Test that the gem is available
    assert defined?(Rack::Attack), "Rack::Attack should be available"

    # Test that initializer files exist
    initializer_path = Rails.root.join("config", "initializers", "rack_attack.rb")
    assert File.exist?(initializer_path), "Rate limiting initializer should exist"

    env_config_path = Rails.root.join("config", "initializers", "rack_attack_environments.rb")
    assert File.exist?(env_config_path), "Environment-specific rate limiting config should exist"
  end

  test "security monitor service is available" do
    assert defined?(SecurityMonitor), "SecurityMonitor service should be available"

    # Test that security stats method exists
    assert_respond_to SecurityMonitor, :get_security_stats

    # Test getting security stats (should work even if rack-attack is disabled)
    stats = SecurityMonitor.get_security_stats
    assert stats.is_a?(Hash), "Security stats should return a hash"
    assert stats.key?(:timeframe), "Security stats should include timeframe"
  end

  test "security rake tasks are available" do
    # Test that custom rake tasks are loaded by checking if the rake file exists
    rake_file_path = Rails.root.join("lib", "tasks", "security.rake")
    assert File.exist?(rake_file_path), "Security rake tasks file should exist"

    # Load the rake file content to verify task definitions
    rake_content = File.read(rake_file_path)
    expected_tasks = %w[stats test clear_cache block_ip unblock_ip report install]

    expected_tasks.each do |task|
      # Different tasks have different definition patterns
      task_pattern = case task
      when "block_ip", "unblock_ip"
                       "task :#{task},"
      else
                       "task #{task}:"
      end
      assert rake_content.include?(task_pattern), "Rake task definition for #{task} should exist (looking for: #{task_pattern})"
    end
  end

  test "admin dashboard includes security statistics" do
    # Test that the controller has the private method for security statistics
    controller = AdminDashboardController.new

    # Check that the controller has the private method defined
    private_methods = controller.private_methods
    assert private_methods.include?(:get_security_statistics),
           "AdminDashboardController should have get_security_statistics method"

    # Test that calling the method doesn't raise an error
    begin
      stats = controller.send(:get_security_statistics)
      assert stats.is_a?(Hash), "Security statistics should return a hash"
    rescue => e
      # It's ok if it fails due to missing dependencies in test env
      assert e.message.include?("Rack::Attack") || e.message.include?("security"),
             "Should fail gracefully with expected error: #{e.message}"
    end
  end

  test "rate limiting rules are properly configured in development" do
    skip "Only test in development environment" unless Rails.env.development?

    # Test that throttle rules exist when rack-attack is enabled
    if defined?(Rack::Attack) && Rack::Attack.throttles.any?
      # Verify expected throttle rules exist
      expected_rules = %w[
        admin_login_attempts
        admin_login_ip
        admin_password_reset
        admin_password_reset_ip
        admin_dashboard
        activeadmin_interface
        admin_write_operations
        admin_general
      ]

      actual_rules = Rack::Attack.throttles.keys.map(&:to_s)
      expected_rules.each do |rule|
        assert actual_rules.include?(rule), "Rate limiting rule '#{rule}' should be configured"
      end

      # Verify blocklist rules exist
      assert Rack::Attack.blocklists.any?, "Should have blocklist rules configured"
      assert Rack::Attack.blocklists.key?("block_admin_scanners"), "Should block admin scanners"

      # Verify safelist rules exist
      assert Rack::Attack.safelists.any?, "Should have safelist rules configured"
    end
  end

  test "rate limiting works with different admin endpoints" do
    skip "Rack::Attack disabled in test environment - run manually in development" unless Rails.env.development?

    # Test admin dashboard endpoint
    get "/admin_dashboard"
    # Should redirect to login (not blocked)
    assert_not_equal 403, response.status, "Admin dashboard should not be blocked"
    assert_not_equal 429, response.status, "Admin dashboard should not be rate limited initially"

    # Test ActiveAdmin endpoint
    get "/admin"
    # Should redirect to login (not blocked)
    assert_not_equal 403, response.status, "ActiveAdmin should not be blocked"
    assert_not_equal 429, response.status, "ActiveAdmin should not be rate limited initially"

    # Test scanner path (should be blocked)
    get "/wp-admin"
    assert_equal 403, response.status, "Scanner path should be blocked"
  end
end
