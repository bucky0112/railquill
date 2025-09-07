class StaticSiteGenerator
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::SanitizeHelper

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
    ApplicationController.render(
      template: "static/index",
      layout: "static",
      assigns: {
        posts: @posts,
        site_config: @site_config,
        page_title: @site_config.site_name
      },
      locals: {
        markdown_to_html: method(:markdown_to_html),
        strip_tags: method(:strip_tags),
        truncate: method(:truncate)
      }
    )
  end

  def render_post(post)
    @site_config = SiteConfig.instance
    ApplicationController.render(
      template: "static/post",
      layout: "static",
      assigns: {
        post: post,
        site_config: @site_config,
        page_title: "#{post.title} - #{@site_config.site_name}"
      },
      locals: {
        markdown_to_html: method(:markdown_to_html)
      }
    )
  end

  def render_about
    @site_config = SiteConfig.instance
    ApplicationController.render(
      template: "static/about",
      layout: "static",
      assigns: {
        site_config: @site_config,
        page_title: "About #{@site_config.site_name}",
        page_description: "Learn more about #{@site_config.site_name} and the story behind this blog."
      },
      locals: {
        markdown_to_html: method(:markdown_to_html)
      }
    )
  end

  def render_archive(posts)
    @site_config = SiteConfig.instance
    ApplicationController.render(
      template: "static/archive",
      layout: "static",
      assigns: {
        posts: posts,
        site_config: @site_config,
        page_title: "Archive - #{@site_config.site_name}",
        page_description: "Browse all #{posts.count} published articles on #{@site_config.site_name}, organized chronologically for easy discovery."
      },
      locals: {
        markdown_to_html: method(:markdown_to_html),
        strip_tags: method(:strip_tags),
        truncate: method(:truncate)
      }
    )
  end

  def render_sitemap(posts)
    @site_config = SiteConfig.instance
    @posts = posts
    @last_modified = [ posts.maximum(:updated_at), @site_config.updated_at ].compact.max

    ApplicationController.render(
      template: "sitemap/index",
      layout: false,
      assigns: {
        posts: @posts,
        site_config: @site_config,
        last_modified: @last_modified
      }
    )
  end

  def render_rss_feed(posts)
    @site_config = SiteConfig.instance
    @posts = posts.limit(20) # Limit RSS to 20 most recent posts
    @last_modified = posts.maximum(:updated_at)
    @base_url = "https://railquill.vercel.app"

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
