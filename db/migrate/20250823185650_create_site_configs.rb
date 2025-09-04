class CreateSiteConfigs < ActiveRecord::Migration[8.0]
  def change
    create_table :site_configs do |t|
      t.string :site_name, null: false, limit: 100
      t.string :welcome_title, null: false, limit: 200
      t.text :welcome_text, null: false
      t.text :about_content, null: false

      t.timestamps
    end

    # Add unique constraint to ensure singleton pattern
    add_index :site_configs, :id, unique: true
  end
end
