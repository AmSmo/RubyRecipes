require 'selenium-webdriver'
require 'nokogiri'
require './simpsons.rb'
require 'pry'
require 'httparty'




class Show
    attr_reader :season_max, :show_main_page, :show_name, :show_main_info,
    :episode_links, :get_episodes, :get_seasons

    def initialize(show)
        @show_name = show
        @show_main_page = search_for(show) 
        @show_main_info = parse_page(@show_main_page)
        @season_max ||= last_season_num(@show_main_info)
        # @show_hash ||= 
    end

    # turns html into CSS sortable objects

    def parse_page(url)
        unparsed_page = HTTParty.get(url)
        return Nokogiri::HTML(unparsed_page)
    end

    # final step to turn it into a json

    def write_to_json(hash, filename)
        File.open("#{filename}.json", "w") do |f|
            f.write(JSON.pretty_generate(hash))
        end
    end


    # takes in show name and sorts through the imdb base link to make
    # sure we are using the right tv show

    def search_for(show)
        show_search_query = show.split.join("+")
        page = "https://www.imdb.com/find?q=#{show_search_query}"
        parsed_search= parse_page(page)
        links = get_search_links(parsed_search)
        find_the_right_answer(links)
    end

    # getting the first 10 possible links

    def get_search_links(parsed_page)
        links = []
        meta_link = parsed_page.css('.result_text > a')
        meta_link.each do |link|
            links << link.attributes["href"].text
        end
        links 
    end

    # opens a browser and then asks if it is the right show

    def find_the_right_answer(links)
        driver = Selenium::WebDriver.for :chrome
        
        found = false
        until found
            links.each do |link|
                puts link
                driver.navigate.to "https://www.imdb.com/#{link[1..-1]}"
                if prompt 
                    driver.close()
                    return "https://www.imdb.com/#{link[1..-1]}"
                end
            end
        end
        driver.close()
    end

    # prompt for the above function to double check we will be
    #    scraping the right file

    def prompt
        puts "Is this the right show?"
        answer = gets.chomp.downcase
        if answer.start_with?("y")
            return true
        elsif answer.start_with?("n")
            return false
        else
            puts "That answer wasn't recognized \n Let's try again \n"
            prompt
        end
    end

    # compiles each episode from the episode links based on season number

    def get_episodes(season_number)
        url = "#{@show_main_page}episodes?season=#{season_number}"
        season = parse_page(url)
        episode_names = get_titles(season)
        links = episode_links(season)
    end

    # MAYBE DEPRECATED, if wanting to use episode names instead of titles for json this becomes important
    def get_titles(episodes)
        titles = episodes.css('div + strong > a').map {|n| n.text}    # all links are stronged
        titles.select { |title| title !~ /^\n/}.count           # only episodes are not with a newline character
        titles
    end

    # gets individual episode links, takes info from above
    
    def episode_links(season)
        episodes = season.css('div + strong > a')
        links = []
        episodes.each do |episode|
            add_on = episode.attributes["href"].value
            links << "http://imdb.com/#{add_on}"
        end
        links
    end

    

    # compiles all the episodes in a season into an info hash
    
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

    # all the info in an episode

    def in_episode(season, episode)
        episode_hash = {}
        episodes = (get_episodes(season))
        current_episode = episodes[episode-1]
        episode_info = parse_page(current_episode)
        characters = characters(episode_info)
        actors = actors(episode_info)
        episode_hash[:title] = title(episode_info)
        episode_hash[:air_date] = air_date(episode_info)
        episode_hash[:plot] = synopsis(episode_info)
        episode_hash[:cast] = cast_assesment(actors, characters)
        episode_hash[:rating] = rating(episode_info).round(2)
        episode_hash[:writers] = writer(episode_info)
        episode_hash[:directors] = director(episode_info)
        episode_hash 
    end


    # ALL THE FOLLOWING ARE HELPER METHODS FOR EPISODE HASH 

    # get characters from a specific episode

    def characters(episode_info)
        episode_info.css('td.character').map {|char| char.text}
        return characters.map { |char| char.gsub(/[[:space:]]+/, " " ).strip}
    end

    # get actors from a specifc episode
    
    def actors(episode_info)
        episode_info.css('.primary_photo > a').map {|inner| inner.children[0].attributes["title"].value}
    end

    # joins actors with their characters

    def cast_assesment(actors, characters)
        i = 0
        cast = {}
        while i <actors.length
            cast[actors[i]] = characters[i].split(" / ")
            i+=1
        end    
        cast
    end

    # episode title that's in the specific hash

    def title(episode_info)
        episode_info.css('h1').text
    end

   # returns air date, there is a whoops because I came across an airdate that was omitted and it broke everything

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


end






# show_info = parse_page(correct_show_link)
# season_max = last_season_num(show_info)

# what_to_gather = how_many_seasons
# translate_answer(what_to_gather,show.split.join("_"),season_max)

    
