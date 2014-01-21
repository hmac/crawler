require "tree"
require "./crawler_base"

def crawl
  node = $queue.shift
  return if node.nil?
  url = node.name
  if not $visited.include?(url) and not url.nil?
    puts url
    $visited.push(url)
    page = page(url)

    # html pages
    links = links_on_page(page)
    links = links.select { |l| local_link?(l) }.map { |l| make_local(l) }.reject { |l| l == url }
    links.each do |l|
      begin
        node << create_node(l, true) 
      rescue Exception => e
      end
    end

    # Non-html assets
    assets = assets_on_page(page).select { |l| local_link?(l) }
    assets.each { |a| node.content[:assets] << a }
    
    node.children.select { |n| n.content[:html] == true }.each { |n| $queue.push(n) }
    $children[url] = node.children
  else
    node.children = $children[url]
  end
  crawl()
end

def create_node(link, is_html)
  Tree::TreeNode.new(link, {html: is_html, assets: []})
end

def start(domain, url)
  $children = {}
  $visited = []
  $domain = domain
  $sitemap = Tree::TreeNode.new(url, {html: true, assets: []})
  $queue = [$sitemap]
  crawl()
end

class Tree::TreeNode
  def print_tree(level = 0)
    if is_root?
      print "*"
    else
      print "|" unless parent.is_last_sibling?
      print(' ' * (level - 1) * 4)
      print(is_last_sibling? ? "+" : "|")
      print "---"
      print(has_children? ? "+" : ">")
    end

    puts " #{name}"

    content[:assets].each { |a| is_root? ? puts(" "+a) : puts((' ' * (level - 1) * 4) + "     " + a) }
    children { |child| child.print_tree(level + 1) if child } # Child might be 'nil'
  end
end