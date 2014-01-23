require "./crawler_base"
require "json"

class Crawler
  def initialize(domain)
    @domain = domain
    @url = "/"
    @pages = {}
    @visited = []
    @queue = [@url]
    parsed_url = URI.parse(@domain)
    @conn = Net::HTTP.new(parsed_url.host, parsed_url.port)
    @conn.use_ssl = true if @domain =~ /^https/
  end

  def crawl(url=nil)
    url ||= @url
    return if url.nil? or @visited.include?(url)
    puts url
    @visited.push(url)

    page = page(url)
    links = links_on_page(page)
    links = links.select { |l| local_link?(l) }.map { |l| make_local(l) }

    # Non-html assets
    assets = assets_on_page(page)
    @pages[url] = assets

    links.each { |l| crawl(l) }
  end

  def create_node(link, html)
    node = {url: link, html: html}
    return node
  end

  def pages
    @pages
  end

  def to_json
    JSON.dump(@pages)
  end

end
