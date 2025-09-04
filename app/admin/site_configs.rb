ActiveAdmin.register SiteConfig do
  permit_params :site_name, :welcome_title, :welcome_text, :about_content

  # Disable new, delete actions since this is a singleton
  actions :all, except: [ :new, :create, :destroy ]

  menu priority: 2, label: "Site Settings"

  controller do
    layout "active_admin"

    def index
      # Redirect to show page for singleton
      redirect_to admin_site_config_path(SiteConfig.instance)
    end

    def show
      @site_config = SiteConfig.instance
    end

    def edit
      @site_config = SiteConfig.instance
    end

    def update
      @site_config = SiteConfig.instance

      if @site_config.update(permitted_params[:site_config])
        redirect_to admin_site_config_path(@site_config), notice: "Site configuration updated successfully."
      else
        render :edit
      end
    end
  end

  # Custom show page with preview capability
  show do
    panel "Site Configuration" do
      attributes_table_for site_config do
        row :site_name
        row :welcome_title
        row :welcome_text do |config|
          div class: "whitespace-pre-wrap" do
            config.welcome_text
          end
        end
        row :about_content do |config|
          div class: "markdown-preview prose prose-sm max-w-none" do
            markdown = Redcarpet::Markdown.new(
              Redcarpet::Render::HTML.new(
                filter_html: false,
                no_images: false,
                no_links: false,
                no_styles: false,
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
            raw markdown.render(config.about_content || "")
          end
        end
        row :updated_at
      end
    end

    panel "Live Preview" do
      div class: "bg-gray-50 p-4 rounded-lg" do
        h4 "Homepage Hero Section Preview:", class: "text-lg font-semibold mb-4"
        div class: "bg-white p-6 rounded border shadow-sm" do
          h2 site_config.welcome_title, class: "text-2xl font-bold mb-4"
          p site_config.welcome_text, class: "text-gray-600"
        end
      end
    end
  end

  form do |f|
    f.inputs "Basic Site Information" do
      f.input :site_name,
              hint: "The name of your site (appears in navigation and titles)"
      f.input :welcome_title,
              hint: "Main heading shown on the homepage"
    end

    f.inputs "Homepage Content" do
      f.input :welcome_text, as: :text, input_html: { rows: 4 },
              hint: "Welcome message displayed on the homepage hero section"
    end

    f.inputs "About Page Content" do
      f.input :about_content, as: :text, input_html: { rows: 20, class: "markdown-editor" },
              label: "About Page Content (Markdown)",
              hint: "Full content for the about page. Supports Markdown formatting."
    end

    f.actions
  end

  # Override the resource path to always use the singleton instance
  def resource
    @resource ||= SiteConfig.instance
  end
end
