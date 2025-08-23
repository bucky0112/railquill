namespace :static do
  desc "Generate static site from published posts"
  task publish: :environment do
    require 'fileutils'
    
    # Create output directory
    output_dir = Rails.root.join('static_site')
    FileUtils.rm_rf(output_dir)
    FileUtils.mkdir_p(output_dir)
    
    # Get published posts
    posts = Post.published.order(created_at: :desc)
    
    # Generate index page
    puts "Generating index page..."
    index_html = StaticSiteGenerator.new.render_index(posts)
    File.write(output_dir.join('index.html'), index_html)
    
    # Generate individual post pages
    posts.each do |post|
      puts "Generating page for: #{post.title}"
      post_html = StaticSiteGenerator.new.render_post(post)
      File.write(output_dir.join("#{post.slug}.html"), post_html)
    end
    
    puts "\nStatic site generated successfully!"
    puts "Output directory: #{output_dir}"
    puts "Total pages generated: #{posts.count + 1}"
  end
end