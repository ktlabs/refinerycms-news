class CreateFeedEntries < ActiveRecord::Migration
  def self.up
    create_table :feed_entries do |t|
      t.string :name
      t.text :summary
      t.text :content
      t.string :url
      t.datetime :published_at
      t.string :entry_id
      t.integer :feed_source_id

      t.timestamps
    end
  end

  def self.down
    drop_table :feed_entries
  end
end