A very basic web crawler
========================

Given a url, will perform a breadth-first crawl of all linked pages (on the same domain and scheme) and build a list of the static assets that each page depends on.
It requires a full url, with scheme (http or https).
Given a subdomain, it will not leave it. i.e. if given `developer.google.com` it will not crawl any pages outside of `developer.google.com`.
It also will not follow redirects.

##Usage:
```ruby
require './crawler.rb'

# A scheme (http or https) is required.
# The crawler will not leave the subdomain (e.g. www) it is assigned
# To see a list of urls as they are being crawled, pass true as an argument to crawl
crawler = Crawler.new("https://www.google.co.uk")
crawler.crawl(true)

crawler.pages # a hash of all assets keyed by url
crawler.to_json # the same thing in JSON
```