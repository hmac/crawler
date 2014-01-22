require "net/http"
require "nokogiri"

# Currently limits to subdomain e.g. google.com will not reach www.google.com

class Crawler

  def local_link?(url)
    # If url starts with /, it's local
    # If it starts with the chosen domain, it's local
    # If it doesn't contain ://, it's local (e.g. "home.html")
    if url[0] == "/" or url.match(Regexp.new("^"+@domain)) or !url.match(/:\/\//)
      true
    else
      false
    end
  end

  def make_local(url)
    # Remove http://domain.tld part
    url = url.gsub(Regexp.new("^"+@domain), "")
    # Remove querystring
    url = url.gsub(/\?.*/, "")
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

  def page(url)
    req = Net::HTTP::Get.new(url)
    res = @conn.request(req)
    Nokogiri::HTML(res.body)
  end

end
