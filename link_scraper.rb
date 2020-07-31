require 'nokogiri'
require 'pry'
require 'httparty'
require './recipe_scraper'

def link_scraper(url) 
    parsed_page = parse_page(url)
    title_page_recipes = parsed_page.css('a.fixed-recipe-card__title-link')
    titles_link = get_titles(title_page_recipes)
end

def get_titles(listings)
    answer = []
    listings.each do |listing|
        recipe= {}
        recipe[:title] = listing.text.strip
        recipe[:link] = listing.attributes["href"].value
        answer << recipe
    end
    answer
end

def parse_page(url)
    unparsed_page = HTTParty.get(url)
    return Nokogiri::HTML(unparsed_page)
end


def into_link
    links = link_scraper('https://www.allrecipes.com')
    every_recipe = []
    links.each do |link|
        url = link[:link]
        recipe = parse_page(url)
        every_recipe << recipe
    end
end

def get_ingredients(recipe)
    # ingredient_css = ['span.ingredients-item-name', ]
    ingredients = recipe.css('span.ingredients-item-name').map {|ingredient| ingredient.text}
    if ingredients.empty?
        ingredients = recipe.css('[itemprop$=dient]').map {|n| n.text}
    end
    ingredients

    

end

def get_directions(recipe)
    directions = recipe.css('li.instructions-section-item').map {|direction| direction.text}
    if directions.empty?
        directions = recipe.css('li span[class^=recipe-direct]').map {|direction| direction.text.strip}
    end
    directions
end