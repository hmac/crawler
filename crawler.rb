require "json"
require "net/http"
require "nokogiri"
require "thread"

class Crawler
  def initialize(domain)
    @domain = domain
    @url = "/"
    @pages = {} # A hash of {url => assets} for each page visited
    @queue = [] # urls waiting to be visited
  end

  # The main loop
  # Here we prefetch the html pages in multiple threads in order
  # to avoid waiting on the network.
  # Ideally we'd want to use some sort of evented IO - (i.e.
  # send off a load of requests in the main loop and register
  # callback functions for when we get a response) but Ruby doesn't
  # natively support this so this is what we're left with.
  # We could also use a proper worker queue system Resque, which
  # would simplify a lot of this.
  #
  # Once the threads have each fetched a page, we parse each one
  # and extract links and assets. Links are added to @queue,
  # and the loop starts from the beginning again.
  def crawl(url)
    url ||= @url
    scrape_page url, page(new_conn(), url)
    while not @queue.empty?
      fetch_queue = Queue.new
      threads = []
      16.times do
        threads << Thread.new do
          url = @queue.pop()
          if url != nil
            conn = new_conn()
            fetch_queue << [url, page(conn, url)]
          end
        end
      end
      threads.each(&:join)
      fetch_queue.length.times do
        page = fetch_queue.pop
        puts page[0]
        scrape_page(page[0], page[1])
      end
    end
  end

  def pages
    @pages
  end

  def to_json
    JSON.dump(@pages)
  end

  private

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

  def new_conn
    parsed_url = URI.parse(@domain)
    conn = Net::HTTP.new(parsed_url.host, parsed_url.port)
    conn.use_ssl = true if @domain =~ /^https/
    return conn
  end

  def local_link?(url)
    # If url starts with /, it's local
    # If it starts with the chosen domain, it's local
    # If it doesn't contain ://, it's local (e.g. "home.html")
    url = url.gsub(/\?.*/, "")

    begin
      uri = URI.parse(url)
    rescue Exception => e
      return false
    end

    (uri.host.nil? or !!@domain.match(Regexp.escape(uri.host))) ? true : false
  end

  def make_local(url)
    # Remove http://domain.tld part
    url = url.gsub(Regexp.new("^"+@domain), "")
    # Remove querystring
    url = url.gsub(/\?.*/, "")
    # Remove url fragment
    url = url.gsub(/#.*/, "")
    # add / if not present
    if url && url[0] != "/"
      url = "/"+url
    end
    return url
  end

  def links_on_page(page)
    page.css("a").map { |a| a.attributes["href"] && a.attributes["href"].value }.compact.uniq
  end

  def assets_on_page(page)
    css = page.css("link").map { |l| l.attributes["href"] && l.attributes["href"].value }.compact.uniq
    scripts = page.css("script").map { |l| l.attributes["src"] && l.attributes["src"].value }.compact.uniq
    images = page.css("img").map { |l| l.attributes["src"] && l.attributes["src"].value }.compact.uniq
    scripts+css+images
  end

  def page(conn, url)
    req = Net::HTTP::Get.new(url)
    res = conn.request(req)
    Nokogiri::HTML(res.body)
  end

end
