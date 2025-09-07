#!/usr/bin/env ruby
# Test script to generate static site and check for issues

# Set the Rails environment
ENV['RAILS_ENV'] ||= 'test'
require_relative 'config/environment'

puts "🚀 Testing Static Site Generation"
puts "================================="
puts "Base URL: #{StaticSiteGenerator::BASE_URL}"
puts

# Load test fixtures
puts "📝 Loading test data..."
ActiveRecord::FixtureSet.create_fixtures('test/fixtures', %w[posts])
posts = Post.published.order(created_at: :desc)
puts "Found #{posts.count} published posts:"
posts.each { |p| puts "  - #{p.title} (#{p.slug})" }
puts

# Generate static site
puts "🏗️  Generating static site..."
generator = StaticSiteGenerator.new
generator.generate_all
puts "✅ Generation complete!"
puts

# Check generated files
output_dir = Rails.root.join("static_site")
puts "📁 Generated files:"
Dir.glob("#{output_dir}/*.{html,xml}").each do |file|
  filename = File.basename(file)
  size = File.size(file)
  puts "  - #{filename} (#{size} bytes)"

  # Check for example.org in critical files
  if [ 'index.html', 'sitemap.xml' ].include?(filename)
    content = File.read(file)
    if content.include?('example.org')
      puts "    ⚠️  Still contains example.org!"
    else
      puts "    ✅ No example.org found"
    end

    # Check for correct domain
    if content.include?('railquill.vercel.app')
      puts "    ✅ Contains correct domain"
    else
      puts "    ⚠️  Missing correct domain"
    end
  end
end
puts

puts "🎯 Check static_site/ directory for generated files"
