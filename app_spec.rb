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
end