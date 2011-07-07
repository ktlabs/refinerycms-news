class FeedSource < ActiveRecord::Base

  has_many :feed_entries

  scope :active, where(:active => true)

end
