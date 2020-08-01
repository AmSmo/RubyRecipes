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
        binding.pry
        every_recipe << recipe
    end
end

def specific_recipe(url)
    recipe = parse_page(url)
    ingredients = get_ingredients(recipe)
    directions = get_directions(recipe)
    
end

def get_ingredients(recipe)
    # ingredient_css = ['span.ingredients-item-name', ]
    ingredients = recipe.css('span.ingredients-item-name').map {|ingredient| ingredient.text.strip}
    if ingredients.empty?
        ingredients = recipe.css('[itemprop$=dient]').map {|n| n.text.strip}
    end
    ingredients
end

def get_directions(recipe)
    directions = recipe.css('li.instructions-section-item').map {|direction| direction.text.strip}
    directions.map! {|di| di.split("\n").map(&:strip).select {|i| i.length>1}}
    if directions.empty?
        directions = recipe.css('li span[class^=recipe-direct]').map {|direction| direction.text.strip}
        directions.map! {|di| di.split("\n").map(&:strip).select {|i| i.length>1}}
    end
    directions
end

def get_name(recipe)
    recipe.css('h1').text
end

def get_classy(recipe)
    name = get_name(recipe)
    ingredients= get_ingredients(recipe)
    directions = get_directions(recipe)
    Recipe.new(name,ingredients,directions)
end