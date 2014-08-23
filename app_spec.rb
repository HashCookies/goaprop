require File.dirname(__FILE__) + '/app.rb'
require 'capybara/rspec'

Capybara.app = Sinatra::Application

RSpec.configure do |config|
  config.include Capybara::DSL
end

describe 'Front End' do
	it "Should have homepage content" do
		visit '/'
		page.should have_content('Real Estate')
	end
end