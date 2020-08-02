opensrequire 'selenium-webdriver'
require 'nokogiri'
require './simpsons.rb'
require 'pry'
require 'httparty'
# def search_for(show)
#     driver = Selenium::WebDriver.for :chrome
#     driver.navigate.to "https://www.imdb.com"
#     search = driver.find_element(:id, "suggestion-search")
#     search.send_keys(show)
#     search.submit()
    
#     binding.pry
# end

def search_for(show)
   
    
    show_search_query = show.split.join("+")
    page = "https://www.imdb.com/find?q=#{show_search_query}"
    parsed_search= parse_page(page)
    links = get_search_links(parsed_search)
    find_the_right_answer(links)
    
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
                return link 
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