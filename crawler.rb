require "./crawler_base"

def crawl
  url = $queue.shift
  return if url.nil?
  if not $visited.include?(url)
    puts url
    $visited.push(url)

    page = page(url)
    links = links_on_page(page)
    links = links.select { |l| local_link?(l) }.map { |l| make_local(l) }
    links.map { |l| $queue.push(l) }

    # Non-html assets
    assets = assets_on_page(page)
    $pages[url] = assets

    
  end
  crawl()
end

def create_node(link, html)
  node = {url: link, html: html}
  return node
end

def start(domain, url)
  $pages = {}
  $visited = []
  $domain = domain
  $queue = [url]
  crawl()
end
