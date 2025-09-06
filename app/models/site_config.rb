class SiteConfig < ApplicationRecord
  # Singleton pattern - only one configuration record allowed
  validates :site_name, presence: true
  validates :welcome_title, presence: true
  validates :welcome_text, presence: true
  validates :about_content, presence: true

  # Ensure only one record exists
  before_create :ensure_single_record

  # Class method to get the singleton instance
  def self.instance
    first_or_create(
      site_name: "Railquill",
      welcome_title: "Welcome to Railquill",
      welcome_text: "Thoughts on Ruby, Rails, and building beautiful web applications. Join me on this journey of continuous learning and clean code.",
      about_content: default_about_content
    )
  end

  # Prevent multiple records
  def self.create(*)
    return instance if any?
    super
  end

  private

  def ensure_single_record
    if self.class.exists?
      errors.add(:base, "Only one site configuration is allowed")
      throw :abort
    end
  end

  def self.default_about_content
    <<~MARKDOWN
      Welcome to **Railquill**, a modern blog platform built with Ruby on Rails, designed for developers who appreciate clean code and beautiful typography.

      ## What is Railquill?

      Railquill is a full-featured blog application that combines the power of Ruby on Rails with modern web technologies. It features a dual admin interface system, static site generation capabilities, and a focus on excellent reading experience.

      ## Key Features

      - **Markdown-based Writing**: Write your posts in Markdown with live preview capabilities
      - **Dual Admin Interface**: Modern custom dashboard alongside traditional ActiveAdmin interface
      - **Static Site Generation**: Generate static HTML files for optimal performance and SEO
      - **Preview System**: Preview draft posts before publishing
      - **Responsive Design**: Beautiful typography and responsive layout that works on all devices
      - **SEO Optimized**: Built-in meta tags, structured data, and search engine optimization

      ## Technology Stack

      - **Framework**: Ruby on Rails 8.0.2
      - **Database**: PostgreSQL
      - **Frontend**: Hotwire (Turbo + Stimulus), Tailwind CSS
      - **JavaScript**: Import maps for ESM modules
      - **Asset Pipeline**: Propshaft
      - **Background Jobs**: Solid Queue, Solid Cache, Solid Cable
      - **Deployment**: Kamal (Docker-based)
      - **Admin**: ActiveAdmin with Devise authentication
      - **Markdown**: Redcarpet renderer with Rouge syntax highlighting

      ## Design Philosophy

      Railquill is built with a focus on:

      - **Performance**: Fast loading times through static generation and optimized assets
      - **Accessibility**: Semantic HTML and proper contrast ratios for all users
      - **Typography**: Beautiful reading experience with carefully chosen fonts and spacing
      - **Developer Experience**: Clean code architecture and comprehensive documentation

      ## Contact

      Have questions or feedback about Railquill? We'd love to hear from you!

      - **Email**: [bucky0112@gmail.com](mailto:bucky0112@gmail.com)
      - **GitHub**: [github.com/bucky0112/railquill](https://github.com/bucky0112/railquill)
      - **Twitter**: [x.com/bucky0112](https://x.com/bucky0112)

      *Thank you for reading and supporting open-source development!*
    MARKDOWN
  end
end
