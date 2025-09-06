class Post < ApplicationRecord
  enum :status, { draft: 0, published: 1 }

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :body_md, presence: true

  before_validation :generate_slug, if: :title_changed?
  before_save :calculate_word_count
  before_save :calculate_reading_time
  before_save :generate_excerpt

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

  def unpublish!
    update!(status: :draft)
  end

  # Ransack configuration for ActiveAdmin
  def self.ransackable_attributes(auth_object = nil)
    [ "body_md", "created_at", "excerpt", "featured_image_url", "id", "meta_description", "published_at", "reading_time", "slug", "status", "title", "updated_at", "word_count" ]
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
end
