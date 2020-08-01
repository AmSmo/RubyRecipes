require 'nokogiri'
require 'pry'
require 'httparty'
require './recipe_scraper'

def parse_page(url)
    unparsed_page = HTTParty.get(url)
    return Nokogiri::HTML(unparsed_page)
end

def get_episodes(season_number)
    url = "https://www.imdb.com/title/tt0096697/episodes?season=#{season_number}"
    season = parse_page(url)
    episode_names = get_titles(season)
    links = episode_links(season)
end

def episode_links(season)
    episodes = season.css('div + strong > a')
    links = []
    episodes.each do |episode|
        add_on = episode.attributes["href"].value
        links << "http://imdb.com/#{add_on}"
    end
    links
end
    
def get_titles(episodes)
    titles = episodes.css('div + strong > a').map {|n| n.text}    # all links are stronged
    titles.select { |title| title !~ /^\n/}.count           # only episodes are not with a newline character
    titles
end

def in_episode(season, episode)
    episode_hash = {}
    episodes = (get_episodes(season))
    this_one = episodes[episode-1]
    episode_info = parse_page(this_one)
    characters = episode_info.css('td.character').map {|char| char.text}
    cleaned_characters = characters.map { |char| char.gsub(/[[:space:]]+/, " " ).strip}
    actors = episode_info.css('.primary_photo > a').map {|inner| inner.children[0].attributes["title"].value}
    episode_hash[:air_date] = air_date(episode_info)
    episode_hash[:plot] = synopsis(episode_info)
    episode_hash[:cast] = cast_assesment(actors,cleaned_characters)
    episode_hash[:rating] = rating(episode_info).round(2)
    binding.pry
end

def cast_assesment(actors, characters)
    i = 0
    cast = {}
    while i <actors.length
        cast[actors[i]] = characters[i].split(" / ")
        i+=1
    end
    
    cast
end

def air_date(episode_info)
    (episode_info.css("[title$=dates]").text.split("aired")[1]).strip
end

def synopsis(episode_info)
    episode_info.css('.canwrap > p  > span').text.strip
end

def rating(episode_info)
    episode_info.css('[itemprop=ratingValue]').text.to_f/2.04
end