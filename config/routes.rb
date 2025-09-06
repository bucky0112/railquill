Rails.application.routes.draw do
  ActiveAdmin.routes(self)
  devise_for :admin_users

  # Custom admin dashboard with modern UI
  get "/admin_dashboard", to: "admin_dashboard#index"

  # Preview routes for authenticated users
  get "preview/:slug", to: "previews#show", as: :preview

  # Static pages
  get "about", to: "static#about"
  get "archive", to: "static#archive"
  get "feed.xml", to: "static#feed", defaults: { format: "xml" }
  get "sitemap.xml", to: "sitemap#index", defaults: { format: "xml" }
  get "posts/:slug", to: "static#post", as: :post
  root to: "static#index"

  # Development: serve static site files (*.html)
  get "/:slug.html", to: "static#static_file", constraints: { slug: /[^\/]+/ }

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
