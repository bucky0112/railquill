namespace :static do
  desc "Generate static site from published posts"
  task publish: :environment do
    puts "🚀 Generating static site..."
    StaticSiteGenerator.new.generate_all
    puts "✅ Static site generation completed!"
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
