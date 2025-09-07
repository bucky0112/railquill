ActiveAdmin.register Post do
  permit_params :title, :slug, :body_md, :status, :published_at, :excerpt,
                :meta_description, :featured_image_url, :featured_image_alt

  # Order posts by published_at for published posts, created_at for drafts
  config.sort_order = "published_at_desc"

  controller do
    layout "active_admin"

    def find_resource
      scoped_collection.find_by!(slug: params[:id])
    end

    def scoped_collection
      resource_class.order(
        Arel.sql("CASE
                    WHEN status = 1 THEN published_at
                    ELSE created_at
                  END DESC NULLS LAST")
      )
    end
  end

  # Custom index with card layout
  index as: :block do |post|
    div class: "bg-white rounded-lg shadow-sm border border-gray-200 p-6 hover:shadow-md transition-all" do
      # Card Header
      div class: "flex justify-between items-start gap-4 mb-4" do
        div class: "flex-1" do
          h3 class: "text-xl font-semibold text-gray-900 mb-1" do
            link_to post.title, admin_post_path(post), class: "hover:text-indigo-600 transition-colors"
          end
        end
        div do
          if post.published?
            span "Published", class: "inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-green-100 text-green-600"
          else
            span "Draft", class: "inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-yellow-100 text-yellow-600"
          end
        end
      end

      # Card Meta
      div class: "flex flex-wrap gap-4 text-sm text-gray-500 mb-4" do
        if post.published?
          span do
            if post.published_at.present?
              "Published #{time_ago_in_words(post.published_at)} ago"
            else
              "Published recently"
            end
          end
        else
          span do
            "Updated #{time_ago_in_words(post.updated_at)} ago"
          end
        end

        if post.reading_time.present?
          span "•", class: "text-gray-300"
          span do
            "#{post.reading_time} min read"
          end
        end

        if post.body_md.present?
          span "•", class: "text-gray-300"
          span do
            "#{post.body_md.split.size} words"
          end
        end
      end

      # Card Excerpt
      if post.excerpt.present? || post.body_md.present?
        div class: "text-gray-600 text-sm leading-relaxed mb-4" do
          para (post.excerpt || strip_tags(post.body_md || "")).truncate(150)
        end
      end

      # Card Actions
      div class: "flex gap-2 pt-4 border-t border-gray-100" do
        link_to "Edit", edit_admin_post_path(post),
                class: "px-4 py-2 bg-indigo-600 text-white text-sm font-medium rounded-lg hover:bg-indigo-500 transition-colors"
        link_to "Preview", preview_admin_post_path(post),
                class: "px-4 py-2 bg-white text-gray-700 text-sm font-medium rounded-lg border border-gray-300 hover:bg-gray-50 transition-colors",
                target: "_blank"
        link_to "View", admin_post_path(post),
                class: "px-4 py-2 bg-white text-gray-700 text-sm font-medium rounded-lg border border-gray-300 hover:bg-gray-50 transition-colors"
      end
    end
  end

  filter :title
  filter :status, as: :select, collection: Post.statuses
  filter :published_at
  filter :created_at
  filter :updated_at

  member_action :preview, method: :get do
    redirect_to preview_path(resource.slug), allow_other_host: false
  end

  action_item :preview, only: :show do
    link_to "Preview", preview_admin_post_path(post), target: "_blank"
  end

  form do |f|
    f.inputs "Basic Information" do
      f.input :title
      f.input :slug, hint: "Leave blank to auto-generate from title"
      f.input :status, as: :select, collection: Post.statuses.keys
      f.input :published_at, as: :datetime_picker,
              hint: "Schedule when this post should be published"
    end

    f.inputs "SEO & Meta" do
      f.input :excerpt, as: :text, input_html: { rows: 3 },
              hint: "Custom excerpt for the post. Leave blank to auto-generate from content."
      f.input :meta_description,
              hint: "SEO meta description. Recommended: 155-160 characters"
      f.input :featured_image_url,
              hint: "URL to the featured image for this post"
      f.input :featured_image_alt, as: :text, input_html: { rows: 2 },
              hint: "Alt text for the featured image (important for accessibility)"
    end

    f.inputs "Content" do
      f.input :body_md, as: :text, input_html: { rows: 20, class: "markdown-editor" },
              label: "Content (Markdown)"
    end

    f.actions
  end

  show do
    attributes_table do
      row :title
      row :slug
      row :status do |post|
        status_tag post.status,
          class: post.published? ? "status_tag green" : "status_tag gray"
      end
      row :published_at
      row :reading_time do |post|
        "#{post.reading_time} minutes" if post.reading_time
      end
      row :excerpt
      row :meta_description
      row :featured_image_url do |post|
        link_to(post.featured_image_url, post.featured_image_url, target: "_blank") if post.featured_image_url.present?
      end
      row :featured_image_alt
      row :created_at
      row :updated_at
    end

    panel "Content Preview" do
      div class: "markdown-preview" do
        markdown = Redcarpet::Markdown.new(
          Redcarpet::Render::HTML.new(
            filter_html: false,  # Allow HTML tags like iframe
            no_images: false,
            no_links: false,
            no_styles: false,    # Allow style attributes for iframe
            safe_links_only: true,
            with_toc_data: true
          ),
          autolink: true,
          tables: true,
          fenced_code_blocks: true,
          lax_spacing: true,
          no_intra_emphasis: true,
          strikethrough: true,
          superscript: true
        )
        raw markdown.render(post.body_md || "")
      end
    end

    panel "Raw Markdown" do
      pre post.body_md
    end
  end
end
