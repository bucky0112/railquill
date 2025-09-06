# frozen_string_literal: true

# Environment-specific rack-attack configuration
Rails.application.configure do
  if Rails.env.development?
    # Relaxed limits for development
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

    # Override default limits with more generous ones for development
    Rails.application.config.after_initialize do
      if defined?(Rack::Attack)
        # Increase development limits significantly
        Rack::Attack.throttles.each do |name, throttle|
          case name
          when "admin_login_attempts"
            throttle.instance_variable_set(:@limit, 20)  # Instead of 5
            throttle.instance_variable_set(:@period, 5.minutes)  # Instead of 15
          when "admin_login_ip"
            throttle.instance_variable_set(:@limit, 50)  # Instead of 10
          when "admin_password_reset"
            throttle.instance_variable_set(:@limit, 10)  # Instead of 3
            throttle.instance_variable_set(:@period, 15.minutes)  # Instead of 1 hour
          when "admin_password_reset_ip"
            throttle.instance_variable_set(:@limit, 30)  # Instead of 10
            throttle.instance_variable_set(:@period, 15.minutes)  # Instead of 1 hour
          when "admin_dashboard"
            throttle.instance_variable_set(:@limit, 300)  # Instead of 120
          when "activeadmin_interface"
            throttle.instance_variable_set(:@limit, 500)  # Instead of 200
          when "admin_write_operations"
            throttle.instance_variable_set(:@limit, 150)  # Instead of 60
          when "admin_general"
            throttle.instance_variable_set(:@limit, 1000)  # Instead of 300
          end
        end
      end
    end

  elsif Rails.env.test?
    # Disable rack-attack in test environment
    Rack::Attack.cache.store = ActiveSupport::Cache::NullStore.new

    Rails.application.config.after_initialize do
      if defined?(Rack::Attack)
        # Disable all throttles in test
        Rack::Attack.throttles.clear
        Rack::Attack.blocklists.clear
      end
    end

  elsif Rails.env.production?
    # Production uses solid_cache by default which is perfect for rack-attack
    # Optionally configure Redis if you prefer (uncomment below)

    # If using Redis instead of solid_cache for rate limiting:
    # redis_config = {
    #   host: ENV.fetch('REDIS_HOST', 'localhost'),
    #   port: ENV.fetch('REDIS_PORT', 6379),
    #   db: ENV.fetch('REDIS_DB', 0),
    #   password: ENV['REDIS_PASSWORD']
    # }
    # Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(**redis_config)

    # Production-specific security enhancements
    Rails.application.config.after_initialize do
      if defined?(Rack::Attack)
        # More aggressive blocking in production
        Rack::Attack.blocklist("block_repeat_offenders") do |req|
          # Block IPs that have been throttled multiple times in the last hour
          Rack::Attack.cache.count("blocklist:#{req.ip}", 1.hour) >= 5
        end

        # Track repeat offenders
        ActiveSupport::Notifications.subscribe("rack.attack") do |name, start, finish, request_id, payload|
          if payload[:name].match?(/(throttle|block)/)
            req = payload[:request]
            Rack::Attack.cache.write("blocklist:#{req.ip}",
                                   (Rack::Attack.cache.read("blocklist:#{req.ip}") || 0) + 1,
                                   1.hour)
          end
        end
      end
    end
  end
end
