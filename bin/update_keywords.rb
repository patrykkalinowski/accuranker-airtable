require 'json'
require 'airrecord'
require 'rest-client'
require 'nokogiri'
require 'uri'

class Keywords < Airrecord::Table
  self.base_key = "appwJtQXPxIJRXGbk"
  self.table_name = "D: Keywords"
end

Airrecord.api_key = ENV['AIRTABLE']


response = RestClient.get(
  "http://app.accuranker.com/api/v4/domains/342476/keywords/?fields=keyword,tags,search_volume.search_volume,search_volume.competition,search_volume.avg_cost_per_click,ranks,search_locale.country_code",
  { "Authorization": "Token #{ENV['ACCURANKER']}",
    :params => {
      "fields": "keyword,tags,search_volume.search_volume,search_volume.competition,ranks,search_locale.country_code"
    }
  }
)

keywords = JSON.parse(response)

keywords.each do |kw|
  # find if current keyword already exists in Airtable
  found = Keywords.all(filter: "{Keyword} = '#{kw['keyword']}'")

  if found[0]
    # if exists
    puts "Updating #{kw['keyword']}"

    record = Keywords.find(found[0].id)

    record["Target URL"] = kw['ranks'][0]['highest_ranking_page']
    record["Position"] = kw['ranks'][0]['rank']
    record["Search Locale"] = kw['search_locale']['country_code']
    record["Tags"] = kw['tags']
    # record["Keyword Difficulty"] = 
    # record["Volume"] = kw['search_volume']['search_volume']
    # record["CPC"] = kw['search_volume']['avg_cost_per_click']

    # search features
    if kw['ranks'][0]['page_serp_features']
      search_features = Array.new
      kw['ranks'][0]['page_serp_features'].each { |key, value| 
        if value == true
          search_features.push(key)
        end
      }

      record["SERP Features"] = search_features
    end

    puts record.fields
    record.save(:typecast => true) # persist to Airtable
  else
    # CREATE
    puts "Creating #{kw['keyword']}"

    url = Keywords.create(
      {
        "Keyword" => kw['keyword'],
        "Target URL" => kw['ranks'][0]['highest_ranking_page'], 
        "Position" => kw['ranks'][0]['rank'],
        "Search Locale" => kw['search_locale']['country_code'],
      },
      {:typecast => true} 
    )
  end
end