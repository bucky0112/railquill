# Monkey patch ActiveAdmin to work with Propshaft instead of Sprockets
# This is necessary because ActiveAdmin 3.3.0 expects Sprockets but Rails 8 uses Propshaft

if defined?(ActiveAdmin) && defined?(Propshaft)
  module ActiveAdmin
    module Views
      module Pages
        class Base < Arbre::HTML::Document
          private

          def build_active_admin_head
            within head do
              meta :content => "text/html; charset=utf-8", "http-equiv" => "Content-Type"
              title do
                text_node [ title, render_or_call_method_or_proc_on(active_admin_namespace.site_title) ].compact.join(" | ")
              end

              active_admin_application.stylesheets.each do |style, options|
                style = style.to_s

                # Skip active_admin.css since we handle it manually
                next if style == "active_admin"

                # Use Rails asset helpers for CSS
                begin
                  if controller.respond_to?(:stylesheet_link_tag)
                    text_node(controller.stylesheet_link_tag(style, **options).html_safe)
                  end
                rescue => e
                  Rails.logger.error "Failed to load stylesheet #{style}: #{e.message}"
                end
              end

              # Include our custom ActiveAdmin CSS - force load with correct path
              begin
                if controller.respond_to?(:stylesheet_link_tag)
                  text_node(controller.stylesheet_link_tag("active_admin", "data-turbo-track": "reload").html_safe)
                else
                  # Direct fallback if helper not available
                  text_node('<link rel="stylesheet" href="/assets/active_admin-456fb2dc.css" data-turbo-track="reload">'.html_safe)
                end
              rescue => e
                Rails.logger.error "Failed to load active_admin stylesheet: #{e.message}"
                # Direct fallback with exact filename
                text_node('<link rel="stylesheet" href="/assets/active_admin-456fb2dc.css" data-turbo-track="reload">'.html_safe)
              end

              active_admin_application.javascripts.each do |src|
                src = src.to_s

                # Skip active_admin.js since we handle it manually
                next if src == "active_admin"

                # Use Rails asset helpers for JS
                begin
                  if controller.respond_to?(:javascript_include_tag)
                    text_node(controller.javascript_include_tag(src).html_safe)
                  end
                rescue => e
                  Rails.logger.error "Failed to load javascript #{src}: #{e.message}"
                end
              end

              # Include our custom ActiveAdmin JS
              if controller.respond_to?(:javascript_include_tag)
                text_node(controller.javascript_include_tag("active_admin", "data-turbo-track": "reload").html_safe)
              end

              if active_admin_namespace.favicon
                favicon = active_admin_namespace.favicon
                favicon_tag = if favicon.start_with?("http")
                  "<link rel=\"shortcut icon\" href=\"#{favicon}\" />"
                else
                  controller.favicon_link_tag(favicon).html_safe
                end
                text_node(favicon_tag.html_safe)
              end

              active_admin_namespace.meta_tags.each do |name, content|
                meta name: name, content: content
              end

              text_node csrf_meta_tag
            end
          end
        end
      end
    end
  end

  # Ensure ActiveAdmin doesn't try to use Sprockets
  ActiveAdmin.setup do |config|
    # Don't clear default stylesheets - let ActiveAdmin handle them
    config.clear_javascripts!

    # Register our custom assets - make sure they're loaded
    config.register_stylesheet "active_admin", media: :all
    config.register_javascript "active_admin"

    # Add Formtastic stylesheets for proper form styling
    config.register_stylesheet "formtastic"

    # Force stylesheets to be included
    # config.stylesheets is a Hash, not Array
  end
end
