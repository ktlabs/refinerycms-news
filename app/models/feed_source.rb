class FeedSource < ActiveRecord::Base

  has_many :feed_entries

  scope :active, where(:active => true)

  # for will_paginate
  def self.per_page
    20
  end

end
