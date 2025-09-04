xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0", "xmlns:atom" => "http://www.w3.org/2005/Atom" do
  xml.channel do
    xml.title "Railquill - Modern Rails Blog"
    xml.description "A modern blog platform built with Ruby on Rails, designed for developers who appreciate clean code and beautiful typography."
    xml.link root_url
    xml.language "en-us"
    xml.managingEditor "hello@railquill.com (Railquill Team)"
    xml.webMaster "hello@railquill.com (Railquill Team)"
    xml.lastBuildDate @posts.first&.published_at&.rfc822 || Time.current.rfc822
    xml.pubDate @posts.first&.published_at&.rfc822 || Time.current.rfc822
    xml.ttl 60
    xml.tag! "atom:link", href: request.original_url, rel: "self", type: "application/rss+xml"

    @posts.each do |post|
      xml.item do
        xml.title post.title
        xml.description do
          xml.cdata! post.excerpt.present? ? post.excerpt : truncate(strip_tags(MarkdownRenderer.render(post.body_md)), length: 300)
        end
        xml.content :encoded do
          xml.cdata! MarkdownRenderer.render(post.body_md)
        end
        xml.link post_url(post.slug)
        xml.guid post_url(post.slug), isPermaLink: true
        xml.pubDate post.published_at&.rfc822 || post.created_at.rfc822
        xml.author "hello@railquill.com (Railquill Team)"

        if post.featured_image_url.present?
          xml.enclosure url: post.featured_image_url, type: "image/jpeg"
        end
      end
    end
  end
end
