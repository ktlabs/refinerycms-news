class AddFeedSourceIdToNewsItem < ActiveRecord::Migration
  def self.up
    add_column ::NewsItem.table_name, :feed_source_id, :integer
  end

  def self.down
    remove_column ::NewsItem.table_name, :feed_source_id
  end
end
