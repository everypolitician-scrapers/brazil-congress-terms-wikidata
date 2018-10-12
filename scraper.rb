#!/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'rest-client'
require 'scraped'
require 'scraperwiki'

class Results < Scraped::JSON
  field :terms do
    json[:results][:bindings].map { |result| fragment(result => Term).to_h }
  end
end

class Term < Scraped::JSON
  field :statement do
    json.dig(:ps, :value).to_s.split('/').last
  end

  field :id do
    json.dig(:ordinal, :value).to_i
  end

  field :name do
    json.dig(:itemLabel, :value)
  end

  field :start_date do
    json.dig(:start_date, :value).to_s[0..9]
  end

  field :end_date do
    json.dig(:end_date, :value).to_s[0..9]
  end

  field :wikidata do
    json.dig(:item, :value).to_s.split('/').last
  end
end

WIKIDATA_SPARQL_URL = 'https://query.wikidata.org/sparql?format=json&query=%s'

def sparql(query)
  result = RestClient.get WIKIDATA_SPARQL_URL, accept: 'text/csv', params: { query: query }
  CSV.parse(result, headers: true, header_converters: :symbol)
rescue RestClient::Exception => e
  raise "Wikidata query #{query} failed: #{e.message}"
end

query = <<SPARQL
  SELECT ?ps ?ordinal ?item ?itemLabel ?start_date ?end_date WHERE {
    ?item p:P31 ?ps .
    ?ps ps:P31 wd:Q15238777 ; pq:P642 wd:Q949699 ; pq:P1545 ?ordinal
    OPTIONAL { ?item wdt:P571 ?start_date }
    OPTIONAL { ?item wdt:P580 ?start_date }
    OPTIONAL { ?item wdt:P576 ?end_date }
    OPTIONAL { ?item wdt:P582 ?end_date }
    FILTER (BOUND(?start_date))
    SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
  }
  ORDER BY xsd:integer(?ordinal)
SPARQL

url = WIKIDATA_SPARQL_URL % CGI.escape(query)
data = Results.new(response: Scraped::Request.new(url: url).response).terms
puts data.map(&:compact).map(&:sort).map(&:to_h) if ENV['MORPH_DEBUG']

ScraperWiki.sqliteexecute('DROP TABLE data') rescue nil
ScraperWiki.save_sqlite(%i[statement], data)
