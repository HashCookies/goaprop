require 'rubygems'
require 'sinatra'
require 'rspec'
require 'capybara/rspec'

require_relative '../app'

RSpec.configure do |config|
	config.include Capybara::DSL
	DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/test.db")
	DataMapper.finalize
	DataMapper.auto_migrate!
  
	tt = Type.first_or_create(:name => "Apartment")
	tt = Type.first_or_create(:name => "House")
	
	rr = Region.create(:name => "North Goa")
	rr = Region.create(:name => "South Goa")
	
	ss = State.first_or_create(:name => "Sale")
	ss = State.first_or_create(:name => "Rent")
	
	cc = Category.create(:name => "Residential")
	cc = Category.create(:name => "Commercial")
	cc = Category.create(:name => "Land")
end