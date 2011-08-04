class FeedSource < ActiveRecord::Base

  has_many :feed_entries
  has_many :news_items

  scope :active, where(:active => true)

  validates :url, :uniqueness => true

  # for will_paginate
  def self.per_page
    20
  end

  def title
    name
  end

end
