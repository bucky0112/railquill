# frozen_string_literal: true

ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: "Dashboard"

  controller do
    layout "active_admin"
  end

  content title: proc { I18n.t("active_admin.dashboard") } do
    div class: "blank_slate_container", id: "dashboard_default_message" do
      span class: "blank_slate" do
        span I18n.t("active_admin.dashboard_welcome.welcome")
        small I18n.t("active_admin.dashboard_welcome.call_to_action")
      end
    end

    columns do
      column do
        panel "Recent Posts" do
          ul do
            Post.published_ordered.limit(5).map do |post|
              li link_to(post.title, admin_post_path(post))
            end
          end
        end
      end

      column do
        panel "Quick Actions" do
          ul do
            li link_to("New Post", new_admin_post_path, class: "button")
            li link_to("Site Settings", admin_site_configs_path, class: "button")
            li link_to("View Site", root_path, class: "button", target: "_blank")
          end
        end
      end
    end
  end
end
