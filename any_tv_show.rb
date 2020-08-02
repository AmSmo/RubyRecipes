require 'selenium-webdriver'
require 'nokogiri'
require './simpsons.rb'
require 'pry'
require 'httparty'


def search_for(show)
    show_search_query = show.split.join("+")
    page = "https://www.imdb.com/find?q=#{show_search_query}"
    parsed_search= parse_page(page)
    links = get_search_links(parsed_search)
    correct_show_link = find_the_right_answer(links)
    show_info = parse_page(correct_show_link)
    season_max = last_season_num(show_info)
    
    what_to_gather = how_many_seasons
    translate_answer(what_to_gather,show.split.join("_"),season_max)
end

def last_season_num(show_info)
    show_info.css('.seasons-and-year-nav > div > a')[0].text.to_i
end

def translate_answer(answer, show,season_max)
    if answer.include?("-")
        seasons= answer.split("-")
        to_be_jsoned = get_all([seasons[0],seasons[1]],show)
        binding.pry
    elsif answer.include?("s")
        season_episode = answer.split(" ")
        season = get_number(season_episode[0])
        episode = get_number(season_episode[1])
        to_be_jsoned = in_episode(season,episode)
    elsif answer.include?("all")
        to_be_jsoned = get_all([1, season_max], show)
    end
    to_be_jsoned
end

def get_number(string)
    string.strip.split("").each {|ele| return ele if ele>0}
end

def how_many_seasons
    puts "If you would like all episodes and all seasons, type 'all'"
    puts "If you would like an entire season enter that number, if you would
            like a range of seasons enter your answer like (2-5)"
    puts "If you want a specific seasons and episode enter S2 E12, for season 2
            episode 12 "
    gets.chomp.downcase
end



def get_search_links(parsed_page)
    links = []
    meta_link = parsed_page.css('.result_text > a')
    meta_link.each do |link|
        links << link.attributes["href"].text
    end
    links
end

def find_the_right_answer(links)
    driver = Selenium::WebDriver.for :chrome
    
    found = false
    links.each do |link|
        until found
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