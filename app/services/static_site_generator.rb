class StaticSiteGenerator
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::SanitizeHelper

  BASE_URL = ENV.fetch("SITE_BASE_URL", "https://railquill.vercel.app")

  def initialize
    # No longer need local markdown renderer - use centralized MarkdownRenderer service
  end

  def generate_all
    require "fileutils"

    # Create output directory
    output_dir = Rails.root.join("static_site")
    FileUtils.rm_rf(output_dir)
    FileUtils.mkdir_p(output_dir)

    # Get published posts
    posts = Post.published.order(created_at: :desc)

    # Generate index page
    Rails.logger.info "Generating index page..."
    index_html = render_index(posts)
    File.write(output_dir.join("index.html"), index_html)

    # Generate about page
    Rails.logger.info "Generating about page..."
    about_html = render_about
    File.write(output_dir.join("about.html"), about_html)

    # Generate archive page
    Rails.logger.info "Generating archive page..."
    archive_html = render_archive(posts)
    File.write(output_dir.join("archive.html"), archive_html)

    # Generate individual post pages
    posts.each do |post|
      Rails.logger.info "Generating page for: #{post.title}"
      post_html = render_post(post)
      File.write(output_dir.join("#{post.slug}.html"), post_html)
    end

    # Generate sitemap
    Rails.logger.info "Generating sitemap..."
    sitemap_xml = render_sitemap(posts)
    File.write(output_dir.join("sitemap.xml"), sitemap_xml)

    # Generate RSS feed
    Rails.logger.info "Generating RSS feed..."
    rss_xml = render_rss_feed(posts)
    File.write(output_dir.join("feed.xml"), rss_xml)

    # Copy static assets (favicons, manifest, etc.)
    Rails.logger.info "Copying static assets..."
    copy_static_assets(output_dir)

    Rails.logger.info "Static site generated successfully!"
    Rails.logger.info "Output directory: #{output_dir}"
    Rails.logger.info "Total pages generated: #{posts.count + 5} (index + about + archive + sitemap + RSS + #{posts.count} posts)"
  end

  def render_index(posts)
    @posts = posts
    @site_config = SiteConfig.instance
    render_template("static/index", "static", {
      posts: @posts,
      site_config: @site_config,
      page_title: @site_config.site_name
    }, {
      markdown_to_html: method(:markdown_to_html),
      strip_tags: method(:strip_tags),
      truncate: method(:truncate)
    }, "/")
  end

  def render_post(post)
    @site_config = SiteConfig.instance
    render_template("static/post", "static", {
      post: post,
      site_config: @site_config,
      page_title: "#{post.title} - #{@site_config.site_name}"
    }, {
      markdown_to_html: method(:markdown_to_html)
    }, "/#{post.slug}.html")
  end

  def render_about
    @site_config = SiteConfig.instance
    render_template("static/about", "static", {
      site_config: @site_config,
      page_title: "About #{@site_config.site_name}",
      page_description: "Learn more about #{@site_config.site_name} and the story behind this blog."
    }, {
      markdown_to_html: method(:markdown_to_html)
    }, "/about")
  end

  def render_archive(posts)
    @site_config = SiteConfig.instance
    render_template("static/archive", "static", {
      posts: posts,
      site_config: @site_config,
      page_title: "Archive - #{@site_config.site_name}",
      page_description: "Browse all #{posts.count} published articles on #{@site_config.site_name}, organized chronologically for easy discovery."
    }, {
      markdown_to_html: method(:markdown_to_html),
      strip_tags: method(:strip_tags),
      truncate: method(:truncate)
    }, "/archive")
  end

  def render_sitemap(posts)
    @site_config = SiteConfig.instance
    @posts = posts
    @last_modified = [ posts.maximum(:updated_at), @site_config.updated_at ].compact.max

    render_template("sitemap/index", false, {
      posts: @posts,
      site_config: @site_config,
      last_modified: @last_modified
    }, {}, "/sitemap.xml")
  end

  def render_rss_feed(posts)
    @site_config = SiteConfig.instance
    @posts = posts.limit(20) # Limit RSS to 20 most recent posts
    @last_modified = posts.maximum(:updated_at)
    @base_url = BASE_URL

    ApplicationController.render(
      template: "feed/index",
      layout: false,
      formats: [ :xml ],
      assigns: {
        posts: @posts,
        site_config: @site_config,
        last_modified: @last_modified,
        base_url: @base_url
      },
      locals: {
        markdown_to_html: method(:markdown_to_html),
        strip_tags: method(:strip_tags),
        truncate: method(:truncate)
      }
    )
  end

  private

  def render_template(template, layout, assigns, locals, path)
    # Create a custom controller to handle rendering with proper URL context
    controller_class = Class.new(ApplicationController) do
      def initialize(base_url, path)
        super()
        @_base_url = base_url
        @_path = path
        setup_request_context
      end

      private

      def setup_request_context
        uri = URI.parse(@_base_url)
        full_url = "#{@_base_url}#{@_path}"

        # Create a mock request with proper URL methods
        mock_request = ActionDispatch::Request.new({
          "REQUEST_METHOD" => "GET",
          "PATH_INFO" => @_path,
          "REQUEST_URI" => @_path,
          "QUERY_STRING" => "",
          "HTTP_HOST" => uri.host,
          "SERVER_NAME" => uri.host,
          "SERVER_PORT" => (uri.port == uri.default_port ? (uri.scheme == "https" ? "443" : "80") : uri.port.to_s),
          "rack.url_scheme" => uri.scheme,
          "HTTPS" => (uri.scheme == "https" ? "on" : "off"),
          "SCRIPT_NAME" => "",
          "HTTP_ACCEPT" => "*/*",
          "HTTP_USER_AGENT" => "StaticSiteGenerator"
        })

        # Override URL methods to return correct values
        mock_request.define_singleton_method(:base_url) { @_base_url }
        mock_request.define_singleton_method(:original_url) { full_url }
        mock_request.define_singleton_method(:url) { full_url }

        @_request = mock_request

        # Set default URL options
        Rails.application.routes.default_url_options = {
          host: uri.host,
          port: (uri.port == uri.default_port ? nil : uri.port),
          protocol: uri.scheme
        }
      end
    end

    controller = controller_class.new(BASE_URL, path)

    # Render the template with the custom controller
    controller.render_to_string(
      template: template,
      layout: layout,
      assigns: assigns,
      locals: locals
    )
  end

  def setup_mock_request(controller, path)
    # Parse the BASE_URL to get host and scheme
    uri = URI.parse(BASE_URL)
    port = uri.port

    # Determine the correct port string for standard ports
    port_string = case uri.scheme
    when "https"
      port == 443 ? "443" : port.to_s
    when "http"
      port == 80 ? "80" : port.to_s
    else
      port.to_s
    end

    # Create a complete Rack environment with proper URL construction
    full_url = "#{uri.scheme}://#{uri.host}#{uri.port == uri.default_port ? '' : ":#{uri.port}"}#{path}"

    env = {
      "REQUEST_METHOD" => "GET",
      "PATH_INFO" => path,
      "REQUEST_URI" => path,
      "QUERY_STRING" => "",
      "HTTP_HOST" => uri.host,
      "SERVER_NAME" => uri.host,
      "SERVER_PORT" => port_string,
      "rack.url_scheme" => uri.scheme,
      "HTTPS" => (uri.scheme == "https" ? "on" : "off"),
      "SCRIPT_NAME" => "",
      "HTTP_ACCEPT" => "*/*",
      "HTTP_USER_AGENT" => "StaticSiteGenerator",
      "HTTP_VERSION" => "HTTP/1.1"
    }

    mock_request = ActionDispatch::Request.new(env)

    # Override the URL methods to ensure they return the correct URLs
    mock_request.define_singleton_method(:base_url) { BASE_URL }
    mock_request.define_singleton_method(:original_url) { full_url }
    mock_request.define_singleton_method(:url) { full_url }

    # Set the request on the controller
    controller.request = mock_request

    # Set the default URL options globally
    Rails.application.routes.default_url_options = {
      host: uri.host,
      port: (uri.port == uri.default_port ? nil : uri.port),
      protocol: uri.scheme
    }

    # Also ensure ActionController::Base has the correct default URL options
    ActionController::Base.default_url_options = Rails.application.routes.default_url_options.dup
  end

  def copy_static_assets(output_dir)
    # List of static files to copy from public/
    static_files = [
      "favicon.ico",
      "icon.svg",
      "icon.png",
      "icon-192.png",
      "icon-512.png",
      "manifest.json",
      "robots.txt",
      "og-image.png",
      "og-image.svg"
    ]

    public_dir = Rails.root.join("public")

    static_files.each do |file|
      source_path = public_dir.join(file)
      dest_path = output_dir.join(file)

      if File.exist?(source_path)
        FileUtils.cp(source_path, dest_path)
        Rails.logger.debug "Copied #{file} to static site"
      else
        Rails.logger.warn "Static file not found: #{file}"
      end
    end
  end

  def markdown_to_html(text)
    # Delegate to the secure MarkdownRenderer service
    MarkdownRenderer.render(text)
  end
end
