require 'nokogiri'
require 'pry'
require 'httparty'
require './recipe_scraper'
require 'json'
def parse_page(url)
    unparsed_page = HTTParty.get(url)
    return Nokogiri::HTML(unparsed_page)
end

def get_all(seasons, show)
    series = {}
    (seasons[0]..seasons[-1]).each do |season_number|
        name = "season_#{season_number}".to_sym
        series[name] = get_seasons(season_number)
    end
    series
    write_to_json(series, show)
end

def write_to_json(hash, filename)
    File.open("#{filename}.json", "w") do |f|
        f.write(JSON.pretty_generate(hash))
    end
end

def get_seasons(season_number)
    season = {}
    episodes = get_episodes(season_number)
    episodes.each_with_index do | episode, i|
        num = i+1
        name = "episode_#{num}".to_sym
        season[name] = in_episode(season_number,num)
    end
    season
    
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
    episode_hash[:title] = title(episode_info)
    episode_hash[:air_date] = air_date(episode_info)
    episode_hash[:plot] = synopsis(episode_info)
    episode_hash[:cast] = cast_assesment(actors,cleaned_characters)
    episode_hash[:rating] = rating(episode_info).round(2)
    episode_hash[:writers] = writer(episode_info)
    episode_hash[:directors] = director(episode_info)
    episode_hash
    
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

def title(episode_info)
    episode_info.css('h1').text
end

def air_date(episode_info)
    if episode_info.css("[title$=dates]").text.split("aired")[1].empty?
        return "whoops"
    else

    return (episode_info.css("[title$=dates]").text.split("aired")[1]).strip 
    end
end

def synopsis(episode_info)
    episode_info.css('.canwrap > p  > span').text.strip
end

def rating(episode_info)
    episode_info.css('[itemprop=ratingValue]').text.to_f/2.04
end

def writer(episode_info)
    crewed= crew(episode_info)
    writers = find_crew(crewed, 'iter')
end

def director(episode_info)
    crewed = crew(episode_info)
    
    directors = find_crew(crewed, 'irecto')
end

def find_crew(crew, position)
    people = []
    crew.each do |crew_member|
        title = crew_member.text
        if title.include?(position)
            while crew_member.next_element.text.length >=2 
                crew_name = crew_member.next_element.text
                people << crew_name if crew_name 
                if crew_member.next_element.next_element != nil
                    crew_member = crew_member.next_element 
                else
                    break
                end
            end
        end 
    end
    people
end

def crew(episode_info)
    crewed = episode_info.css('.inline')
end