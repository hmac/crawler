require "./crawler_base"
require "json"
require "thread"

class Crawler
  def initialize(domain)
    @domain = domain
    @url = "/"
    @pages = {}
    parsed_url = URI.parse(@domain)
    @conn = Net::HTTP.new(parsed_url.host, parsed_url.port)
    @conn.use_ssl = true if @domain =~ /^https/
    @queue = []
  end

  def new_conn
    parsed_url = URI.parse(@domain)
    conn = Net::HTTP.new(parsed_url.host, parsed_url.port)
    conn.use_ssl = true if @domain =~ /^https/
    return conn
  end

  def crawl(url=nil)
    url ||= @url
    return if url.nil?
    scrape_page url, page(@conn, url)
    while not @queue.empty?
      pages = Queue.new
      threads = []
      16.times do
        threads << Thread.new do
          url = @queue.pop()
          if url != nil
            conn = new_conn()
            pages << [url, page(conn, url)]
          end
        end
      end
      threads.each(&:join)
      pages.length.times do
        page = pages.pop
        puts page[0]
        scrape_page(page[0], page[1])
      end
    end
  end

  # def scrape_page(conn, url)
    # page = page conn, url
  def scrape_page(url, page)
    links = links_on_page(page)
    links = links.select { |l| local_link?(l) }.map { |l| make_local(l).strip }.reject { |l| l == "" }
    assets = assets_on_page(page)
    @pages[url] = assets
    links.each do |l|
      unless @pages.keys.include? l
        @queue.push l
        @pages[l] ||= {}
      end
    end
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
