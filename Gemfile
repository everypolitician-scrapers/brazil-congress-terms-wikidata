# frozen_string_literal: true

ruby '2.4.4'

source 'https://rubygems.org'
git_source(:github) { |repo_name| "https://github.com/#{repo_name}.git" }

gem 'rest-client'
gem 'scraped', github: 'everypolitician/scraped'
gem 'scraperwiki', github: 'openaustralia/scraperwiki-ruby', branch: 'morph_defaults'
gem 'sqlite_magic', github: 'openc/sqlite_magic'

group :test do
  gem 'rubocop'
end

group :development do
  gem 'pry'
end
