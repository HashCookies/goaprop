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
	property :location,			String
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
	
	belongs_to :product
	
	
end

DataMapper.auto_upgrade!

get '/' do
	@property = Property.get(1)
	erb :home
end

get 'properties' do
	erb :home
end

