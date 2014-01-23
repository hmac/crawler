A very basic web crawler
========================

Usage:
````
require './crawler.rb'

# A scheme (http or https) is required.
# The crawler will not leave the subdomain (e.g. www) it is assigned
crawler = Crawler.new("https://www.google.co.uk")
crawler.crawl

crawler.pages # a hash of all assets keyed by url
crawler.to_json # JSON output
````