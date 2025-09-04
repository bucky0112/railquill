# frozen_string_literal: true

class Admin::ApplicationController < ActiveAdmin::BaseController
  # Use our custom layout for all admin pages
  layout "active_admin"

  # Set page title before each action
  before_action :set_page_title

  private

  def set_page_title
    @page_title = case controller_name
    when "dashboard"
      "Dashboard"
    when "posts"
      case action_name
      when "index"
        "Posts"
      when "new", "create"
        "New Post"
      when "edit", "update"
        "Edit Post"
      when "show"
        "Post Details"
      else
        "Posts"
      end
    when "admin_users"
      "Admin Users"
    else
      controller_name.humanize
    end
  end
end
