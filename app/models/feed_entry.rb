class FeedEntry < ActiveRecord::Base

  belongs_to :feed_source

  def self.full_fetch_feed(feed_source, start_date)
    feed = Feedzirra::Feed.fetch_and_parse(feed_source.url)

    if feed.respond_to?('etag')
      feed_source.etag          = feed.etag
      feed_source.last_modified = feed.last_modified
      feed_source.save

      self.add_entries(feed.entries, feed_source, start_date)
    end
  end

  def self.full_fetch_active_feeds(start_date = nil)
    FeedSource.active.each do |source|
      self.full_fetch_feed(source, start_date)
    end
  end

  def self.update_feed(feed_source, start_date)
    feed_to_update               = Feedzirra::Parser::Atom.new
    feed_to_update.feed_url      = feed_source.url
    feed_to_update.etag          = feed_source.etag
    feed_to_update.last_modified = feed_source.last_modified

    last_entry     = Feedzirra::Parser::AtomEntry.new
    last_entry.url = feed_source.last_entry_url

    feed_to_update.entries = [last_entry]

    feed = Feedzirra::Feed.update(feed_to_update)

    feed_source.etag          = feed.etag
    feed_source.last_modified = feed.last_modified
    feed_source.save

    self.add_entries(feed.new_entries, feed_source, start_date) if feed.updated?
  end

  def self.update_active_feeds(start_date = nil)
    FeedSource.active.each do |source|
      source.last_modified.nil? ?
        self.full_fetch_feed(source, start_date) :
        self.update_feed(source, nil)
    end
  end

  private

  def self.add_entries(entries, feed_source, start_date)
    locale = I18n.locale
    
    unless entries.blank?
      entries.reverse.each do |entry| 
        if !exists?(:entry_id => entry.id) && 
          (start_date.blank? || (entry.published >= start_date))
    
          if entry.content.blank?
            if entry.summary.blank?
              unparsed_content = entry.title
            else
              unparsed_content = entry.summary
            end
          else
            unparsed_content = entry.content
          end
    
          if feed_source.pattern.blank?
            parsed_content = unparsed_content
          else
            temp_parsed_content = Nokogiri::HTML(unparsed_content).at_css(feed_source.pattern)
            if temp_parsed_content.blank?
              parsed_content = unparsed_content
            else
              parsed_content = temp_parsed_content.inner_html
            end
          end
    
          if feed_source.img_pattern.blank?
            img_id = nil
          else
            parsed_img     = Nokogiri::HTML(unparsed_content).at_css(feed_source.img_pattern)
            
            if parsed_img.nil?
              img_id = nil
            else
              image_url      = parsed_img.attributes["src"].value
              
              unless image_url.start_with?("http")
                prefix = feed_source.url.match(/http[sS]?:\/\/[^\/]+/)[0]
                prefix = '/' + prefix unless image_url.match(/\A\//)[0]
                
                image_url = prefix + image_url
              end
              
              img_plain      = HTTParty.get(image_url)
              img_ext        = img_plain.headers["content-type"].sub("image/", "")
              
              img_file = Tempfile.new("news_items_image.#{img_ext}")
              img_file.binmode
              img_file.write(img_plain.body)
              img_file.rewind
              
              img = Image.create(
                :image => img_file
              )
              img.image_name = "news_item_image.#{img_ext}"
              img.image_ext  = img_ext
              img.save!
              img_id = img.id
              
              img_file.close!
            end
          end
    
          create!(
            :name           => entry.title,
            :summary        => entry.summary,
            :url            => entry.url,
            :published_at   => entry.published,
            :entry_id       => entry.id,
            :feed_source_id => feed_source.id,
            :content        => parsed_content
          )
          
          I18n.locale = :en
          news_item = NewsItem.create(
            :title => entry.title,
            :body => entry.url,
            :publish_date => DateTime.now,
            :created_at => entry.published,
            :feed_source_id => feed_source.id,
            :image_id => img_id
          )
          
          I18n.locale = :ru
          news_item.title = entry.title
          news_item.body  = self.truncate(parsed_content)
          news_item.save
        end
      end
    
      feed_source.last_entry_url = entries.first.url
      feed_source.save
    end
    
    I18n.locale = locale
  end
  
  def self.truncate(str)
    result = ""
    index = 0
    str.each_char do |x|
      result << x unless index > 200
      index += 1
    end
    return result
  end
  
end
