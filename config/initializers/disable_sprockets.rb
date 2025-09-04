# Ensure Sprockets is completely disabled in favor of Propshaft
# This prevents conflicts when gems like sassc-rails try to load Sprockets

Rails.application.config.before_initialize do
  # Remove Sprockets railtie if it's been loaded
  if defined?(Sprockets::Railtie)
    Rails.application.config.assets = ActiveSupport::OrderedOptions.new
    Rails.application.config.assets.compile = false
    Rails.application.config.assets.enabled = false
  end
end

# Ensure we're using Propshaft helpers
Rails.application.config.after_initialize do
  # Override any Sprockets helpers that might have been loaded
  if defined?(Sprockets::Rails::Helper)
    ActiveSupport.on_load(:action_view) do
      # Remove Sprockets helpers module if included
      if self.included_modules.include?(Sprockets::Rails::Helper)
        # Can't remove a module, but we can ensure Propshaft helpers take precedence
        include Propshaft::Helper if defined?(Propshaft::Helper)
      end
    end
  end
end
