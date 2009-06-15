xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title "Rising Trends for <%= Time.now.strftime("%A, %B %d, %Y") %>"
    xml.description "trendingtopics.org rising trends"
    xml.link pages_url

    for post in @posts
      xml.item do
        xml.title post.title
        xml.description post.content
        xml.pubDate post.created_at.to_s(:rfc822)
        xml.link post_url(post)
      end
    end
  end
end
