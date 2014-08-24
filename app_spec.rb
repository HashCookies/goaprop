require File.dirname(__FILE__) + '/app.rb'
require 'capybara/rspec'

Capybara.app = Sinatra::Application

RSpec.configure do |config|
  config.include Capybara::DSL
end

describe 'Visiting home page' do
	it "Should have homepage content" do
		visit '/'
		page.should have_content('Real Estate')
	end
end

describe "visiting services page" do
	it "should have required content" do
		visit '/about'
		page.should have_content('Hassle-free Real Estate')
		page.should have_button('Search')
	end
end

describe "Searching for property" do
	before do
		visit '/'
		first(:button, "Search").click
	end
	it "should load the search page" do
		page.should have_content("Locations")
	end
	it "should have a property listing" do
		page.should have_content("Renovated")
	end
end

describe "Visit Sell/Lease" do
	before { visit '/sell-lease' }
	it "should have the required content" do
		page.should have_title("GoaPropertyCo | Sell or Lease Your Property")
	end
end

describe "Searching for Sale Property in North Goa" do
	before {visit '/search?search%5Bcategory%5D=1&search%5Bstate%5D=1&search%5Bregion_id%5D=1&submit=' }
	it "Should have a property for sale from Mapusa" do
		page.should have_content("Blank")
	end
end

describe "Creating a new property" do
	before do 
		page.driver.browser.authorize 'hashcookies', 'iomega'
		visit '/property/new' 
	end
	it "should have the required content" do
		page.should have_content("Create A New Property")
	end
end