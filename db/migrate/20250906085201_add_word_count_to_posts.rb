class AddWordCountToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :word_count, :integer, default: 0, null: false
    add_index :posts, :word_count

    # Backfill word count for existing posts
    reversible do |dir|
      dir.up do
        Post.find_each do |post|
          word_count = post.body_md.to_s.split.size
          post.update_column(:word_count, word_count)
        end
      end
    end
  end
end
