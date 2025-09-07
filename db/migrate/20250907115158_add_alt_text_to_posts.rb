class AddAltTextToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :featured_image_alt, :text
  end
end
