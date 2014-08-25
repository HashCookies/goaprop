require 'rubygems'
require 'bundler'
Bundler.setup(:default, :test)
require 'sinatra'
require 'rspec'
require 'rack/test'
require 'capybara/rspec'

# set test environment
Sinatra::Base.set :environment, :test
Sinatra::Base.set :run, false
Sinatra::Base.set :raise_errors, true
Sinatra::Base.set :logging, false

require File.join(File.dirname(__FILE__), 'app')

Capybara.app = Sinatra::Application

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