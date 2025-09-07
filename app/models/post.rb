class Post < ApplicationRecord
  enum :status, { draft: 0, published: 1 }

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :body_md, presence: true

  before_validation :generate_slug, if: :title_changed?
  before_save :calculate_word_count
  before_save :calculate_reading_time
  before_save :generate_excerpt
  before_save :ensure_published_at
  after_update :regenerate_static_site, if: :should_regenerate_static_site?

  scope :published, -> { where(status: :published) }
  scope :published_ordered, -> { published.order(published_at: :desc) }

  def to_param
    slug
  end

  def html_content
    @html_content ||= MarkdownRenderer.render(body_md)
  end

  def next_post
    Post.published.where("published_at > ?", published_at || created_at).order(published_at: :asc).first
  end

  def previous_post
    Post.published.where("published_at < ?", published_at || created_at).order(published_at: :desc).first
  end

  def publish!
    update!(status: :published, published_at: published_at || Time.current)
  end

  # Ensure published_at is always set when status changes to published
  def ensure_published_at
    if published? && published_at.blank?
      self.published_at = Time.current
    end
  end

  def unpublish!
    update!(status: :draft)
  end

  # Ransack configuration for ActiveAdmin
  def self.ransackable_attributes(auth_object = nil)
    [ "body_md", "created_at", "excerpt", "featured_image_alt", "featured_image_url", "id", "meta_description", "published_at", "reading_time", "slug", "status", "title", "updated_at", "word_count" ]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

  private

  def generate_slug
    self.slug = title.parameterize if title.present?
  end

  def calculate_word_count
    return unless body_md.present?
    self.word_count = body_md.split.size
  end

  def calculate_reading_time
    return unless word_count.present? && word_count > 0

    words_per_minute = 200
    self.reading_time = (word_count.to_f / words_per_minute).ceil
  end

  def generate_excerpt
    return if excerpt.present?
    return unless body_md.present?

    # Strip markdown and take first 160 characters
    plain_text = body_md.gsub(/[#*_\[\]()]/, "").strip
    self.excerpt = plain_text.truncate(160)
  end

  def should_regenerate_static_site?
    # Regenerate if:
    # 1. Status changed (draft -> published or published -> draft)
    # 2. Content changed for published posts
    # 3. Title, slug, or other important fields changed for published posts
    return false unless saved_changes.any?

    status_changed = saved_changes.key?("status")
    content_fields_changed = (saved_changes.keys & [ "title", "body_md", "excerpt", "published_at", "slug" ]).any?

    # Regenerate if status changed OR if important fields changed on a published post
    status_changed || (published? && content_fields_changed)
  end

  def regenerate_static_site
    Rails.logger.info "🚀 Queuing static site regeneration due to post changes: #{title}"

    begin
      if Rails.env.test?
        # Don't regenerate in test environment
        nil
      elsif Rails.env.development?
        # In development, use immediate background process for faster feedback
        pid = spawn("bin/rails static:publish", chdir: Rails.root, out: "/dev/null", err: "/dev/null")
        Process.detach(pid)  # Don't wait for it to finish
      else
        # In production, use proper background job system
        StaticSiteGenerationJob.perform_later(reason: "post_changed:#{slug}")
      end
    rescue => e
      Rails.logger.error "❌ Failed to queue static site regeneration: #{e.message}"
    end
  end
end
