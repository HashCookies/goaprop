require 'rubygems'
require 'sinatra'
require 'data_mapper'
require 'sass'


get '/css/style.css' do
	content_type 'text/css', :charset => 'utf-8'
	scss(:"css/style")
end

configure :development do
	require 'dm-sqlite-adapter'
	DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/products.db")
end

class Property
	include DataMapper::Resource
	
	property :id,				Serial
	property :title,			String
	
	property :desc,				String
	property :area,				Integer	# Written in a standard unit like "2000" that can be then interpreted. 
										# This value will not be shown to the user. Used for sorting.
	property :area_detail,		String	# Written in natural language, like "2000 x 4200 sq ft"
	property :price,			Integer
	property :sanad,			Boolean # Unsure what this option is in the real world, but defaults to false
	property :area,				String
	property :area_built,		String
	
	property :for_buy,			Boolean
	property :for_rent,			Boolean
	property :is_commercial,	Boolean # This and the next option allows property to have both booleans to be true.
	property :is_residential,	Boolean
	
	property :location_id,		Integer # This ties in with the locations Model written out below. 
										# So Location == 1 would find and get "Panaji"
	property :type_id,			Integer # Implies property type from Model "Type" like "Apartment", House, "Property", "Villa"
	property :region_id,		Integer # Similar to above, refers to model Region
	
	property :viewcount,		Integer # automatically incremented every time instance pulled from db.
	
	has n, :images
	belongs_to :location
	belongs_to :type
end

class Image
	include DataMapper::Resource
	
	property :id,			Serial
	property :product_id,	Integer
	property :url, 			String
	
	belongs_to :property
end

class Location
	include DataMapper::Resource
	
	property :id,			Serial
	property :name,			String
	property :region_id,	Integer
	
	belongs_to :region
	has n, :properties
end

class Region
	include DataMapper::Resource
	
	property :id,		Serial
	property :name,		String
	
	has n, :properties
end

class Type
	include DataMapper::Resource
	
	property :id,		Serial
	property :name,		String
	
	has n, :properties
	
end

DataMapper.auto_upgrade!

before do
	@page_title = "GoaPropertyCo"
end

get '/' do
	erb :home
end

get '/properties' do
	erb :home
end

get '/properties/new' do
	
	@page_title += " | New Property"
	erb :new
end

post '/create' do
	@property = Property.new(params[:property])
	if @property.save
		redirect "/properties/#{@property.id}"
	else
		redirect '/'
	end
end

get '/properties/:id' do
	@property = Property.get params[:id]
	erb :property
end

get '/properties' do
	@properties = Property.all
end