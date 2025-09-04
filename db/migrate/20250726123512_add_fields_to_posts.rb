class AddFieldsToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :published_at, :datetime
    add_column :posts, :excerpt, :text
    add_column :posts, :meta_description, :string
    add_column :posts, :featured_image_url, :string
    add_column :posts, :reading_time, :integer

    add_index :posts, :published_at
    add_index :posts, [ :status, :published_at ]
  end
end
