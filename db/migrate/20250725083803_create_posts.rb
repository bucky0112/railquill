class CreatePosts < ActiveRecord::Migration[8.0]
  def change
    create_table :posts do |t|
      t.string :title
      t.string :slug
      t.text :body_md
      t.integer :status

      t.timestamps
    end
    add_index :posts, :slug
  end
end
