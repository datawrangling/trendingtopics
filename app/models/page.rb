class Page < ActiveRecord::Base
  has_one :daily_timeline
  named_scope :title_like, lambda { |query| { :conditions => ['title like ?', "#{query}%"], :order => '`total_pageviews` DESC', :limit => 20 } }
end
