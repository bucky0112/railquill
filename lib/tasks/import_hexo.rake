namespace :import do
  desc "Import posts from Hexo blog directory"
  task hexo: :environment do
    require "yaml"

    hexo_posts_dir = "/Users/buckychu/sideProjects/Travis-hexo-blog/source/_posts"

    unless Dir.exist?(hexo_posts_dir)
      puts "❌ Hexo posts directory not found: #{hexo_posts_dir}"
      exit 1
    end

    imported_count = 0
    skipped_count = 0
    error_count = 0

    puts "🚀 Starting Hexo posts import from #{hexo_posts_dir}"
    puts "=" * 60

    Dir.glob("#{hexo_posts_dir}/*.md").each do |file_path|
      begin
        filename = File.basename(file_path, ".md")

        # Skip image files
        next if File.extname(filename) == ".png"

        content = File.read(file_path, encoding: "UTF-8")

        # Parse YAML front matter
        if content =~ /\A---\s*\n(.*?)\n---\s*\n(.*)\z/m
          yaml_content = $1
          body_content = $2.strip

          begin
            front_matter = YAML.safe_load(yaml_content, permitted_classes: [ Date, Time ], aliases: true)
          rescue Psych::SyntaxError => e
            puts "⚠️  Failed to parse YAML in #{filename}: #{e.message}"
            error_count += 1
            next
          end

          # Extract data from front matter
          title = front_matter["title"]&.strip
          date = front_matter["date"]
          description = front_matter["decription"] || front_matter["description"] # Handle typo

          # Skip if essential data is missing
          if title.blank?
            puts "⚠️  Skipping #{filename}: Missing title"
            skipped_count += 1
            next
          end

          # Generate slug from filename (more reliable than title for Hexo posts)
          slug = filename.parameterize
          # If parameterize returns empty string (for non-ASCII filenames), use title
          if slug.blank? && title.present?
            slug = title.parameterize
          end
          # Fallback to filename itself if still blank
          if slug.blank?
            slug = filename.gsub(/[^a-zA-Z0-9\-_]/, "-").squeeze("-").chomp("-")
          end

          # Check if post already exists
          if Post.exists?(slug: slug)
            puts "⏭️  Skipping #{filename}: Post with slug '#{slug}' already exists"
            skipped_count += 1
            next
          end

          # Parse date
          published_at = nil
          if date
            begin
              published_at = case date
              when String
                             DateTime.parse(date)
              when Date, Time, DateTime
                             date
              else
                             nil
              end
            rescue ArgumentError => e
              puts "⚠️  Invalid date format in #{filename}: #{date} (#{e.message})"
              published_at = nil
            end
          end

          # Extract excerpt (content before <!--more--> or from description)
          excerpt = nil
          if body_content.include?("<!--more-->")
            excerpt_content = body_content.split("<!--more-->").first.strip
            # Clean up markdown for excerpt
            plain_text = excerpt_content.gsub(/[#*_\[\]()]/, "").strip
            excerpt = plain_text.truncate(160) if plain_text.present?
          elsif description.present?
            excerpt = description.truncate(160)
          end

          # Create the post
          post = Post.new(
            title: title,
            slug: slug,
            body_md: body_content,
            status: published_at ? :published : :draft,
            published_at: published_at,
            excerpt: excerpt,
            meta_description: description&.truncate(160)
          )

          if post.save
            puts "✅ Imported: #{title} (#{slug})"
            imported_count += 1
          else
            puts "❌ Failed to save #{filename}: #{post.errors.full_messages.join(', ')}"
            error_count += 1
          end

        else
          puts "⚠️  Skipping #{filename}: No YAML front matter found"
          skipped_count += 1
        end

      rescue StandardError => e
        puts "❌ Error processing #{filename}: #{e.message}"
        puts e.backtrace.first(3).join("\n") if ENV["DEBUG"]
        error_count += 1
      end
    end

    puts "=" * 60
    puts "📊 Import Summary:"
    puts "   ✅ Imported: #{imported_count} posts"
    puts "   ⏭️  Skipped:  #{skipped_count} posts"
    puts "   ❌ Errors:   #{error_count} posts"
    puts "   📝 Total processed: #{imported_count + skipped_count + error_count} files"
    puts "=" * 60
    puts "🎉 Import completed!"

    if imported_count > 0
      puts "\n💡 Next steps:"
      puts "   • Visit /admin to review imported posts"
      puts "   • Run 'bin/publish' to generate static site"
      puts "   • Check posts at /admin_dashboard for a modern view"
    end
  end
end
