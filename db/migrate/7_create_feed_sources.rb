class CreateFeedSources < ActiveRecord::Migration
  def self.up
    create_table :feed_sources do |t|
      t.string  :name
      t.string  :url
      t.string  :pattern
      t.string  :img_pattern
      t.boolean :active
      t.string  :etag
      t.time    :last_modified
      t.string  :last_entry_url

      t.timestamps
    end
  end

  def self.down
    drop_table :feed_sources
  end
end
