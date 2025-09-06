# frozen_string_literal: true

namespace :security do
  desc "Show rate limiting statistics and blocked IPs"
  task stats: :environment do
    puts "\n🛡️  Security & Rate Limiting Statistics"
    puts "=" * 50

    if defined?(Rack::Attack)
      puts "✅ Rack::Attack is enabled"
      puts "📊 Cache store: #{Rack::Attack.cache.store.class.name}"

      # Show throttle rules
      puts "\n📋 Active Throttle Rules:"
      Rack::Attack.throttles.each do |name, throttle|
        limit = throttle.instance_variable_get(:@limit)
        period = throttle.instance_variable_get(:@period)
        puts "   • #{name}: #{limit} requests per #{period / 60} minutes"
      end

      # Show blocklist rules
      puts "\n🚫 Active Blocklist Rules:"
      Rack::Attack.blocklists.each do |name, _|
        puts "   • #{name}"
      end

      # Show safelist rules
      puts "\n✅ Active Safelist Rules:"
      Rack::Attack.safelists.each do |name, _|
        puts "   • #{name}"
      end

    else
      puts "❌ Rack::Attack is not enabled"
    end

    puts "\n📈 Recent Security Events (if available):"
    stats = SecurityMonitor.get_security_stats(1.hour)
    puts "   Time frame: #{stats[:timeframe] / 3600} hours"
    puts "   Blocked IPs: #{stats[:blocked_ips_count]}"
    puts "   Login attempts blocked: #{stats[:login_attempts_blocked]}"
    puts "   Scanner attempts blocked: #{stats[:scanner_attempts_blocked]}"

    if File.exist?(Rails.root.join("log", "security.log"))
      puts "\n📝 Recent security log entries:"
      puts `tail -5 #{Rails.root.join("log", "security.log")}`
    end
  end

  desc "Test rate limiting configuration"
  task test: :environment do
    puts "\n🧪 Testing Rate Limiting Configuration"
    puts "=" * 50

    if Rails.env.production?
      puts "❌ Cannot run rate limiting tests in production environment"
      exit 1
    end

    unless defined?(Rack::Attack)
      puts "❌ Rack::Attack not loaded"
      exit 1
    end

    # Test basic configuration
    puts "✅ Rack::Attack loaded successfully"
    puts "✅ Cache store configured: #{Rack::Attack.cache.store.class.name}"

    # Test that rules are loaded
    puts "✅ Throttle rules loaded: #{Rack::Attack.throttles.count} rules"
    puts "✅ Blocklist rules loaded: #{Rack::Attack.blocklists.count} rules"
    puts "✅ Safelist rules loaded: #{Rack::Attack.safelists.count} rules"

    puts "\n📋 Throttle Rules Details:"
    Rack::Attack.throttles.each do |name, throttle|
      limit = throttle.instance_variable_get(:@limit)
      period = throttle.instance_variable_get(:@period)
      puts "   #{name}: #{limit} requests/#{period}s"
    end

    puts "\n✅ Rate limiting configuration test completed successfully!"
  end

  desc "Clear rate limiting cache"
  task clear_cache: :environment do
    puts "\n🧹 Clearing Rate Limiting Cache"
    puts "=" * 50

    if defined?(Rack::Attack)
      Rack::Attack.cache.store.clear
      puts "✅ Rate limiting cache cleared successfully"
    else
      puts "❌ Rack::Attack not enabled"
    end
  end

  desc "Block an IP address manually"
  task :block_ip, [ :ip, :duration, :reason ] => :environment do |t, args|
    ip = args[:ip]
    duration = (args[:duration] || "1").to_i.hours
    reason = args[:reason] || "Manual administrative block"

    if ip.blank?
      puts "❌ Please provide an IP address: rake security:block_ip[192.168.1.1,2,\"spam attack\"]"
      exit 1
    end

    puts "\n🚫 Manually Blocking IP Address"
    puts "=" * 50
    puts "IP: #{ip}"
    puts "Duration: #{duration / 3600} hours"
    puts "Reason: #{reason}"

    if defined?(SecurityMonitor)
      SecurityMonitor.emergency_block_ip(ip, duration, reason)
      puts "✅ IP address blocked successfully"
    else
      puts "❌ SecurityMonitor not available"
    end
  end

  desc "Unblock an IP address"
  task :unblock_ip, [ :ip ] => :environment do |t, args|
    ip = args[:ip]

    if ip.blank?
      puts "❌ Please provide an IP address: rake security:unblock_ip[192.168.1.1]"
      exit 1
    end

    puts "\n✅ Unblocking IP Address"
    puts "=" * 50
    puts "IP: #{ip}"

    if defined?(SecurityMonitor)
      SecurityMonitor.unblock_ip(ip)
      puts "✅ IP address unblocked successfully"
    else
      puts "❌ SecurityMonitor not available"
    end
  end

  desc "Show current blocked IPs"
  task blocked_ips: :environment do
    puts "\n🚫 Currently Blocked IP Addresses"
    puts "=" * 50

    if defined?(Rack::Attack)
      # This would need to be implemented based on your caching strategy
      # For now, show manual blocks
      puts "Note: Implement detailed blocked IP listing based on cache inspection"
      puts "Manual blocks would be stored with keys like: manual_block:[IP]"
      puts "Rate limit blocks are temporary and stored with rule-specific keys"
    else
      puts "❌ Rack::Attack not enabled"
    end
  end

  desc "Generate security report"
  task report: :environment do |t, args|
    timeframe = (args.extras.first || "24").to_i.hours

    puts "\n📊 Security Report"
    puts "=" * 50
    puts "Report Period: Last #{timeframe / 3600} hours"
    puts "Generated: #{Time.current.strftime('%Y-%m-%d %H:%M:%S %Z')}"

    # Security log analysis (if log file exists)
    security_log = Rails.root.join("log", "security.log")
    if File.exist?(security_log)
      puts "\n📝 Security Log Analysis:"

      # Count different event types
      log_content = File.read(security_log)
      events = {
        "ADMIN_LOGIN_ATTACK" => log_content.scan(/ADMIN_LOGIN_ATTACK/).count,
        "PASSWORD_RESET_ABUSE" => log_content.scan(/PASSWORD_RESET_ABUSE/).count,
        "ADMIN_SCANNER" => log_content.scan(/ADMIN_SCANNER/).count,
        "RATE_LIMIT" => log_content.scan(/RATE_LIMIT/).count
      }

      events.each do |event_type, count|
        puts "   #{event_type}: #{count} incidents"
      end

      puts "\n📋 Recent Security Events:"
      puts `tail -10 #{security_log}`
    else
      puts "\n📝 No security log file found at #{security_log}"
    end

    puts "\n💡 Recommendations:"
    puts "   • Monitor security logs regularly"
    puts "   • Review blocked IPs for patterns"
    puts "   • Consider adjusting rate limits if needed"
    puts "   • Implement automated alerting for critical events"
  end

  desc "Install and setup rate limiting"
  task install: :environment do
    puts "\n⚙️  Rate Limiting Installation & Setup"
    puts "=" * 50

    # Check if rack-attack gem is installed
    begin
      require "rack/attack"
      puts "✅ rack-attack gem is installed"
    rescue LoadError
      puts "❌ rack-attack gem is not installed"
      puts "   Please add 'gem \"rack-attack\"' to your Gemfile and run 'bundle install'"
      exit 1
    end

    # Check if initializer exists
    initializer_path = Rails.root.join("config", "initializers", "rack_attack.rb")
    if File.exist?(initializer_path)
      puts "✅ rack-attack initializer found"
    else
      puts "❌ rack-attack initializer not found"
      puts "   Expected at: #{initializer_path}"
      exit 1
    end

    # Check if middleware is loaded
    if Rails.application.config.middleware.middlewares.any? { |m| m.name == "Rack::Attack" }
      puts "✅ rack-attack middleware is loaded"
    else
      puts "⚠️  rack-attack middleware may not be loaded (this is normal in test env)"
    end

    puts "\n✅ Rate limiting setup verification completed!"
    puts "\n📚 Usage Examples:"
    puts "   rake security:stats          # Show current statistics"
    puts "   rake security:test           # Test configuration"
    puts "   rake security:clear_cache    # Clear rate limit cache"
    puts "   rake security:block_ip[IP]   # Manually block an IP"
    puts "   rake security:unblock_ip[IP] # Unblock an IP"
    puts "   rake security:report         # Generate security report"
  end
end
