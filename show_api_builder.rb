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

end






# show_info = parse_page(correct_show_link)
# season_max = last_season_num(show_info)

# what_to_gather = how_many_seasons
# translate_answer(what_to_gather,show.split.join("_"),season_max)

    
