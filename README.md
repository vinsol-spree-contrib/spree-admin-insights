SpreeReportify
==============

spree_reportify is a spree extension which provide insights to admin. Following analysis are provided by this extension
1) Finance Analysis
  This analysis provides insights on different aspects of business like which is the most frequently used payment method, sales tax collected every month etc.
2) Product Analysis
  This analysis provides insights on most purchased product, most viewed product, product added to cart most number of times etc.
3) Promotion Analysis
  This analysis provides insights on the usage of promotions
4) Trending Search Analysis
  This analysis provided insights on the the keywords that are generally used by the users to search products
5) User Analysis
  This analysis provided insights on user activities like users who recently signed up, users who recently purchased products

Installation
------------

Add spree_reportify to your Gemfile:

```ruby
gem 'spree_reportify'
```

Bundle your dependencies and run the installation generator:

```shell
bundle
bundle exec rails g spree_reportify:install
```

Testing
-------

First bundle your dependencies, then run `rake`. `rake` will default to building the dummy app if it does not exist, then it will run specs. The dummy app can be regenerated by using `rake test_app`.

```shell
bundle
bundle exec rake
```

When testing your applications integration with this extension you may use it's factories.
Simply add this require statement to your spec_helper:

```ruby
require 'spree_reportify/factories'
```

Copyright (c) 2016 [name of extension creator], released under the New BSD License
