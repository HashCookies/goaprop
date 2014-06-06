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
	property :location,			Integer
	property :area,				String
	property :price,			Integer
	property :sanad,			Boolean
	property :area,				String
	property :area_built,		String
	property :type,				Integer
	
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
	@property = Property.get(1)
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