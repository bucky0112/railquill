# frozen_string_literal: true

class SecurityMonitor
  # Service class for monitoring and analyzing security events from rack-attack

  def self.setup_monitoring
    # Subscribe to rack-attack events for detailed logging and alerting
    ActiveSupport::Notifications.subscribe("rack.attack") do |name, start, finish, request_id, payload|
      new(payload).handle_security_event
    end
  end

  def initialize(payload)
    @payload = payload
    @request = payload[:request]
    @matched_rule = payload[:name]
  end

  def handle_security_event
    case @matched_rule
    when /login_attempts/
      handle_login_attack
    when /password_reset/
      handle_password_reset_abuse
    when /block_admin_scanners/
      handle_scanner_attack
    when /admin_/
      handle_admin_abuse
    else
      handle_general_rate_limit
    end

    # Log to security log file in production
    log_security_event if Rails.env.production?

    # Send alerts for critical events
    send_alert if critical_event?
  end

  private

  def handle_login_attack
    Rails.logger.warn security_log_message(
      "ADMIN_LOGIN_ATTACK",
      "Excessive admin login attempts detected",
      {
        ip: @request.ip,
        email: extract_email,
        user_agent: @request.user_agent,
        attempts_in_window: cache_count_for_ip
      }
    )
  end

  def handle_password_reset_abuse
    Rails.logger.warn security_log_message(
      "PASSWORD_RESET_ABUSE",
      "Password reset abuse detected",
      {
        ip: @request.ip,
        email: extract_email,
        user_agent: @request.user_agent
      }
    )
  end

  def handle_scanner_attack
    Rails.logger.error security_log_message(
      "ADMIN_SCANNER",
      "Admin scanner/bot detected",
      {
        ip: @request.ip,
        path: @request.path,
        user_agent: @request.user_agent,
        referer: @request.referer
      }
    )
  end

  def handle_admin_abuse
    Rails.logger.warn security_log_message(
      "ADMIN_INTERFACE_ABUSE",
      "Excessive admin interface usage",
      {
        ip: @request.ip,
        path: @request.path,
        method: @request.request_method,
        rate_limit_rule: @matched_rule
      }
    )
  end

  def handle_general_rate_limit
    Rails.logger.info security_log_message(
      "RATE_LIMIT",
      "General rate limit exceeded",
      {
        ip: @request.ip,
        path: @request.path,
        rule: @matched_rule
      }
    )
  end

  def security_log_message(event_type, description, details)
    {
      timestamp: Time.current.iso8601,
      event_type: event_type,
      description: description,
      details: details,
      request_id: @payload[:request_id]
    }.to_json
  end

  def extract_email
    @request.params.dig("admin_user", "email") || "unknown"
  end

  def cache_count_for_ip
    # Try to get the current count from rack-attack cache
    key = "admin_login_attempts:#{@request.ip}:#{extract_email}"
    Rack::Attack.cache.read(key) || 0
  end

  def critical_event?
    # Define which events should trigger alerts
    %w[
      ADMIN_LOGIN_ATTACK
      PASSWORD_RESET_ABUSE
      ADMIN_SCANNER
    ].include?(@matched_rule.to_s.upcase) ||
    @matched_rule =~ /block_/
  end

  def log_security_event
    # In production, you might want to log to a separate security log file
    # or send to a security monitoring service like Datadog, New Relic, etc.
    security_logger.warn(security_log_message(
      @matched_rule.to_s.upcase,
      "Rate limit or block triggered",
      {
        ip: @request.ip,
        path: @request.path,
        user_agent: @request.user_agent,
        timestamp: Time.current.iso8601
      }
    ))
  end

  def send_alert
    # In production, implement actual alerting:
    # - Email notifications
    # - Slack/Discord webhooks
    # - PagerDuty integration
    # - Security monitoring service alerts

    Rails.logger.error "[SECURITY ALERT] #{@matched_rule}: #{@request.ip} #{@request.path}"

    # Example: Slack webhook (implement if needed)
    # SlackNotifier.new.send_security_alert(
    #   event: @matched_rule,
    #   ip: @request.ip,
    #   path: @request.path
    # )
  end

  def security_logger
    @security_logger ||= Logger.new(Rails.root.join("log", "security.log")).tap do |logger|
      logger.formatter = proc do |severity, datetime, progname, msg|
        "[#{datetime}] #{severity} #{msg}\n"
      end
    end
  end

  # Class method to get security statistics
  def self.get_security_stats(timeframe = 1.hour)
    # This would be more sophisticated in production with proper analytics
    # For now, return basic info that could be shown on admin dashboard

    {
      timeframe: timeframe,
      generated_at: Time.current.iso8601,
      note: "Implement with analytics service for detailed statistics",
      blocked_ips_count: 0,  # Would query rack-attack cache
      login_attempts_blocked: 0,  # Would query logs or metrics
      scanner_attempts_blocked: 0,  # Would query logs or metrics
      total_rate_limits_hit: 0  # Would query logs or metrics
    }
  end

  # Method to manually block an IP (for emergency use)
  def self.emergency_block_ip(ip_address, duration = 1.hour, reason = "Manual block")
    Rack::Attack.cache.write("manual_block:#{ip_address}", reason, duration)
    Rails.logger.error "[MANUAL_BLOCK] IP #{ip_address} blocked for #{duration} seconds. Reason: #{reason}"

    # Add to rack-attack blocklist temporarily
    Rack::Attack.blocklist("manual_block_#{ip_address}") do |req|
      req.ip == ip_address && Rack::Attack.cache.read("manual_block:#{ip_address}")
    end
  end

  # Method to unblock an IP
  def self.unblock_ip(ip_address)
    Rack::Attack.cache.delete("manual_block:#{ip_address}")
    Rails.logger.info "[MANUAL_UNBLOCK] IP #{ip_address} unblocked"
  end
end

# Initialize monitoring when Rails starts
if defined?(Rails) && Rails.env.production?
  Rails.application.config.after_initialize do
    SecurityMonitor.setup_monitoring
  end
end
