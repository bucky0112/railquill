class AdminDashboardController < ApplicationController
  before_action :authenticate_admin_user!
  layout false

  def index
    @posts = Post.all
    @total_posts = Post.count
    @published_posts = Post.published.count
    @draft_posts = Post.draft.count
    @total_reading_time = Post.published.sum(:reading_time) || 0
    @recent_posts = Post.order(
      Arel.sql("CASE 
                  WHEN status = 1 THEN published_at 
                  ELSE created_at 
                END DESC NULLS LAST")
    ).limit(8)
    @total_words = Post.published.sum { |p| p.body_md.to_s.split.size }
    @avg_reading_time = Post.published.average(:reading_time).to_i
    @posts_this_month = Post.published.where("published_at >= ?", 1.month.ago).count
    @posts_last_month = Post.published.where("published_at >= ? AND published_at < ?", 2.months.ago, 1.month.ago).count
    
    # Calculate growth metrics
    @posts_growth = calculate_growth(@posts_this_month, @posts_last_month)
    @published_this_week = Post.published.where("published_at >= ?", 1.week.ago).count
    @total_views = @published_posts * Random.rand(50..500) # Mock data - replace with real analytics
    
    # Recent activity timeline
    @recent_activity = generate_activity_timeline
  end
  
  private
  
  def calculate_growth(current, previous)
    return 0 if previous == 0
    ((current - previous).to_f / previous * 100).round(1)
  end
  
  def generate_activity_timeline
    activities = []
    
    # Recent posts
    @recent_posts.limit(5).each do |post|
      activities << {
        type: post.published? ? 'published' : 'drafted',
        title: post.title,
        time: post.published? ? post.published_at : post.created_at,
        slug: post.slug,
        reading_time: post.reading_time
      }
    end
    
    # Sort by time desc and return recent 10
    activities.sort_by { |a| a[:time] || Time.current }.reverse.first(10)
  end
end