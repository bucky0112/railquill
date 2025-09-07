namespace :static do
  desc "Generate static site from published posts"
  task publish: :environment do
    require "fileutils"

    # Create output directory
    output_dir = Rails.root.join("static_site")
    FileUtils.rm_rf(output_dir)
    FileUtils.mkdir_p(output_dir)

    # Get published posts
    posts = Post.published.order(created_at: :desc)

    # Generate index page
    puts "Generating index page..."
    index_html = StaticSiteGenerator.new.render_index(posts)
    File.write(output_dir.join("index.html"), index_html)

    # Generate about page
    puts "Generating about page..."
    about_html = StaticSiteGenerator.new.render_about
    File.write(output_dir.join("about.html"), about_html)

    # Generate archive page
    puts "Generating archive page..."
    archive_html = StaticSiteGenerator.new.render_archive(posts)
    File.write(output_dir.join("archive.html"), archive_html)

    # Generate individual post pages
    posts.each do |post|
      puts "Generating page for: #{post.title}"
      post_html = StaticSiteGenerator.new.render_post(post)
      File.write(output_dir.join("#{post.slug}.html"), post_html)
    end

    # Generate sitemap
    puts "Generating sitemap..."
    sitemap_xml = StaticSiteGenerator.new.render_sitemap(posts)
    File.write(output_dir.join("sitemap.xml"), sitemap_xml)

    puts "\nStatic site generated successfully!"
    puts "Output directory: #{output_dir}"
    puts "Total pages generated: #{posts.count + 4} (index + about + archive + sitemap + #{posts.count} posts)"
  end

  desc "Queue static site generation as background job"
  task queue: :environment do
    puts "🚀 Queuing static site generation job..."
    StaticSiteGenerationJob.perform_later(reason: "manual_queue")
    puts "✅ Job queued successfully!"
    puts "Monitor with: bin/rails solid_queue:status"
  end

  desc "Force regenerate static site (bypass cache)"
  task force: :environment do
    puts "🔄 Force regenerating static site..."
    Rake::Task["static:publish"].invoke
  end
end
