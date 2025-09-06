# frozen_string_literal: true

class Rack::Attack
  # Configure cache store - use Rails cache for consistency with app
  cache.store = Rails.cache

  # Custom throttle key based on IP and request fingerprint
  class Request < ::Rack::Request
    def admin_login_identifier
      # Use IP + email if present in params to handle distributed attacks better
      "#{ip}:#{params['admin_user']&.dig('email')}"
    end

    def admin_action_identifier
      "#{ip}:admin"
    end

    def password_reset_identifier
      # Use IP + email to prevent abuse of specific accounts from different IPs
      "#{ip}:#{params['admin_user']&.dig('email')}"
    end
  end

  ### ADMIN AUTHENTICATION PROTECTION ###

  # Block excessive admin login attempts
  # Very strict: 5 attempts per 15 minutes per IP+email combination
  throttle("admin_login_attempts", limit: 5, period: 15.minutes) do |req|
    if req.post? && req.path.match?(%r{^/admin_users/sign_in})
      req.admin_login_identifier
    end
  end

  # Additional protection: Block admin login after failed attempts from IP
  # Moderate: 10 attempts per 15 minutes per IP (catches distributed attacks)
  throttle("admin_login_ip", limit: 10, period: 15.minutes) do |req|
    if req.post? && req.path.match?(%r{^/admin_users/sign_in})
      req.ip
    end
  end

  # Password reset abuse prevention
  # Strict: 3 password reset requests per hour per IP+email
  throttle("admin_password_reset", limit: 3, period: 1.hour) do |req|
    if req.post? && req.path.match?(%r{^/admin_users/password})
      req.password_reset_identifier
    end
  end

  # Additional password reset protection by IP
  # Moderate: 10 password reset requests per hour per IP
  throttle("admin_password_reset_ip", limit: 10, period: 1.hour) do |req|
    if req.post? && req.path.match?(%r{^/admin_users/password})
      req.ip
    end
  end

  ### ADMIN INTERFACE PROTECTION ###

  # Custom admin dashboard protection
  # Reasonable: 120 requests per minute per IP (2 per second)
  throttle("admin_dashboard", limit: 120, period: 1.minute) do |req|
    if req.path.start_with?("/admin_dashboard")
      req.admin_action_identifier
    end
  end

  # ActiveAdmin interface protection
  # Moderate: 200 requests per minute per IP (allows for complex admin operations)
  throttle("activeadmin_interface", limit: 200, period: 1.minute) do |req|
    if req.path.start_with?("/admin") && !req.path.start_with?("/admin_dashboard")
      req.admin_action_identifier
    end
  end

  # Admin POST/PUT/DELETE operations (more restrictive)
  # Conservative: 60 write operations per minute per IP
  throttle("admin_write_operations", limit: 60, period: 1.minute) do |req|
    if (req.path.start_with?("/admin") || req.path.start_with?("/admin_dashboard")) &&
       %w[POST PUT PATCH DELETE].include?(req.request_method)
      req.admin_action_identifier
    end
  end

  ### GENERAL PROTECTION ###

  # Protect against excessive requests to any admin endpoint
  # Generous but prevents abuse: 300 requests per minute per IP
  throttle("admin_general", limit: 300, period: 1.minute) do |req|
    if req.path.match?(%r{^/(admin|admin_dashboard|admin_users)})
      req.ip
    end
  end

  # Block obviously malicious requests
  # Ban IPs that make requests to common attack paths
  blocklist("block_admin_scanners") do |req|
    # Common admin scanner paths that don't exist in our app
    suspicious_paths = %w[
      /administrator /wp-admin /cpanel /phpmyadmin
      /admin.php /admin/login /backend /control
      /manager /webmaster /siteadmin
    ]

    suspicious_paths.any? { |path| req.path.start_with?(path) }
  end

  ### SAFELIST ###

  # Allow higher limits for localhost in development
  safelist("localhost") do |req|
    Rails.env.development? && req.ip == "127.0.0.1"
  end

  # Allow higher limits for Docker development environment
  safelist("docker_dev") do |req|
    Rails.env.development? && %w[172.18.0.1 172.17.0.1].include?(req.ip)
  end

  ### RESPONSE CUSTOMIZATION ###

  # Customize response for different types of throttling
  self.throttled_responder = lambda do |env|
    match_data = env["rack.attack.match_data"]

    case env["rack.attack.matched"]
    when "admin_login_attempts", "admin_login_ip"
      # Security-focused message for login attempts
      [
        429,
        { "Content-Type" => "text/html; charset=utf-8" },
        [ "<html><body><h1>Too Many Login Attempts</h1><p>Please wait before trying again.</p></body></html>" ]
      ]
    when "admin_password_reset", "admin_password_reset_ip"
      [
        429,
        { "Content-Type" => "text/html; charset=utf-8" },
        [ "<html><body><h1>Password Reset Limit Exceeded</h1><p>Please wait before requesting another password reset.</p></body></html>" ]
      ]
    else
      # Generic rate limit message for admin interface
      [
        429,
        { "Content-Type" => "text/html; charset=utf-8" },
        [ "<html><body><h1>Rate Limit Exceeded</h1><p>Please slow down and try again later.</p></body></html>" ]
      ]
    end
  end

  # Customize response for blocked requests
  self.blocklisted_responder = lambda do |env|
    [
      403,
      { "Content-Type" => "text/html; charset=utf-8" },
      [ "<html><body><h1>Forbidden</h1><p>Access denied.</p></body></html>" ]
    ]
  end

  ### NOTIFICATION HOOKS ###

  # Log security events for monitoring
  ActiveSupport::Notifications.subscribe("rack.attack") do |name, start, finish, request_id, payload|
    req = payload[:request]

    case payload[:name]
    when "admin_login_attempts", "admin_login_ip"
      Rails.logger.warn "[SECURITY] Admin login rate limit hit: IP=#{req.ip} Path=#{req.path} Email=#{req.params['admin_user']&.dig('email')}"
    when "admin_password_reset", "admin_password_reset_ip"
      Rails.logger.warn "[SECURITY] Password reset abuse detected: IP=#{req.ip} Email=#{req.params['admin_user']&.dig('email')}"
    when "block_admin_scanners"
      Rails.logger.error "[SECURITY] Admin scanner blocked: IP=#{req.ip} Path=#{req.path} User-Agent=#{req.user_agent}"
    end
  end
end

# Enable rack-attack
Rails.application.config.middleware.use Rack::Attack unless Rails.env.test?
