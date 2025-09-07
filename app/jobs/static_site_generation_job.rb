class StaticSiteGenerationJob < ApplicationJob
  queue_as :default

  # Retry failed jobs with exponential backoff
  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(reason: "manual")
    Rails.logger.info "🚀 Starting static site generation (#{reason})"

    begin
      # Use the StaticSiteGenerator service to generate the site
      generator = StaticSiteGenerator.new
      generator.generate_all

      Rails.logger.info "✅ Static site generation completed successfully"
    rescue => e
      Rails.logger.error "❌ Static site generation failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end
  end
end
