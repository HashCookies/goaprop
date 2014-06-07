require 'rubygems'
require 'sinatra'
require 'data_mapper'
require 'sass'

configure :development do
	require 'dm-sqlite-adapter'
	DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/products.db")
end

class Property
	include DataMapper::Resource
	
	property :id,				Serial
	property :title,			String
	property :desc,				String
	property :location,			Integer # This ties in with the locations Model written out below. So Location == 1 would find and get "Panaji"
	property :area,				Integer	# Written in a standard unit like "2000" that can be then interpreted. 
										# This value will not be shown to the user. Used for sorting.
	property :area_detail,		String	# Written in natural language, like "2000 x 4200 sq ft"
	property :price,			Integer
	property :sanad,			Boolean # Unsure what this option is in the real world, but defaults to false
	property :area,				String
	property :area_built,		String
	property :type,				Integer # Implies property type like "Apartment", House, "Property", "Villa"
	property :for_buy,			Boolean
	property :for_rent,			Boolean
	property :is_commercial,	Boolean # This and the next option allows property to have both booleans to be true.
	property :is_residential,	Boolean
	
	property :viewcount,		Integer
	
	has n, :images
	
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
	
	property :id,		Serial
	property :name,		String
end

class Type
	include DataMapper::Resource
	
	property :id,		Serial
	property :name,		String
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

get '/property/new' do
	
	@page_title += " | New Property"
	erb :new
end

post '/create' do
	@property = Property.new(params[:property])
	if @property.save
		redirect "/property/#{@property.id}"
	else
		redirect '/'
	end
end

get '/property/:id' do
	@property = Property.get params[:id]
	erb :property
end

get '/properties' do
	@properties = Property.all
end