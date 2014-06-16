require 'rubygems'
require 'sinatra'
require 'sinatra/support/numeric'
require 'data_mapper'
require 'sass'


get '/css/style.css' do
	content_type 'text/css', :charset => 'utf-8'
	scss(:"css/style")
end

configure :development do
	require 'dm-sqlite-adapter'
	DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/db.db")
end

DataMapper::Property::String.length(255)
DataMapper::Model.raise_on_save_failure = true 

class Main < Sinatra::Base
  register Sinatra::Numeric
end

class Property
	include DataMapper::Resource
	
	property :id,				Serial
	property :title,			String
	
	property :area,				Integer	# Written in a standard unit like "2000" that can be then interpreted. 
										# This value will not be shown to the user. Used for sorting.
	property :area_detail,		String	# Written in natural language, like "2000 x 4200 sq ft"
	property :price,			Integer
	property :sanad,			Boolean # Unsure what this option is in the real world, but defaults to false
	property :area_built,		String
	property :featured_img,		Integer
	property :slug,				String
	
	property :for_buy,			Boolean
	property :for_rent,			Boolean
	property :is_commercial,	Boolean # This and the next option allows property to have both booleans to be true.
	property :is_residential,	Boolean
		
	property :viewcount,		Integer # automatically incremented every time instance pulled from db.
	property :region_id,		Integer
	
	has n, :images
#	has n, :regions, :through => Resource
	belongs_to :location
	belongs_to :type
	
	def handle_upload(file)
		path = File.join(Dir.pwd, "/public/properties/images", file[:filename].downcase.gsub(" ", "-"))
		File.open(path, "wb") do |f|
			f.write(file[:tempfile].read)
		end
		
	end
	
	
	
end

class Image
	include DataMapper::Resource
	
	property :id,			Serial
	property :product_id,	Integer
	property :url, 			String
	
	belongs_to :property
end

class Type
	include DataMapper::Resource
	
	property :id,		Serial
	property :name,		String
	
	has n, :propertys
	
end

class Location
	include DataMapper::Resource
	
	property :id,			Serial
	property :name,			String
	
	has n, :regions, :through => Resource
	has n, :propertys
	
end

class Region
	include DataMapper::Resource
	
	property :id,		Serial
	property :name,		String
	
	has n, :locations, :through => Resource
#	has n, :propertys, :through => Resource
	
end

DataMapper.auto_upgrade!

tt = Type.first_or_create(:name => "Apartment")
rr = Region.first_or_create(:name => "North Goa")

before do
	@page_title = "GoaPropertyCo"
end

get '/' do
	@types = Type.all
	@regions = Region.all
	@properties = Property.all
	@region = Region.first
	@properties.each do |property|
		property.featured_img = Image.get(property.featured_img).url unless Image.get(property.featured_img).nil?
		property.texttype = Type.get(property.type_id).title
	end
	erb :home
end

get '/properties' do
	@properties = Property.all
	@region = Region.first
	@properties.each do |property|
		property.featured_img = Image.get(property.featured_img).url unless Image.get(property.featured_img).nil?
		property.texttype = Type.get(property.type_id).title
	end
	erb :properties
end

get '/property/new' do
	@regions = Region.all
	@locations = Location.all
	@types = Type.all
	@page_title += " | New Property"
	erb :new
end

post '/create' do
	location = Location.get(params[:location][:id])
	type = Type.get(params[:type][:id])
	
	update_params = params[:property]
	update_params[:for_buy] = params[:property][:for_buy] == 'on' ? true : false
	update_params[:for_rent] = params[:property][:for_rent] == 'on' ? true : false
	property = Property.new(update_params)
	
	location.propertys << property
	type.propertys << property
	
	if property.save	
		
		if !params[:images].nil?
			params[:images].each do |image|
				property.images.create({ :property_id => property.id, :url => image[:filename].downcase.gsub(" ", "-") })
				property.handle_upload(image)
			end
		end
		
		if !params[:featured].nil?
			@featured = property.images.create({ :property_id => property.id, :url => params[:featured][:filename].downcase.gsub(" ", "-") })
			property.handle_upload(params[:featured])
			property.update({ :featured_img => @featured.id })
		end
		
		redirect "/property/#{property.id}"
	else
		redirect '/properties'
	end
end

get '/property/:id' do
	@property = Property.get params[:id]
	@images = @property.images[1..3]
	@property.featured_img = Image.get(@property.featured_img).url unless Image.get(@property.featured_img).nil?
	
	@properties = Property.all
	@properties.each do |property|
		property.featured_img = Image.get(property.featured_img).url unless Image.get(property.featured_img).nil?
	end
	erb :property
end

get '/properties' do
	@properties = Property.all
end

get '/search' do
	search = params[:search]
	
	@properties = Property.all(search[:buysell] => true, :type_id => search[:type_id], :region_id => search[:region_id])
	@properties.each do |property|
		property.featured_img = Image.get(property.featured_img).url unless Image.get(property.featured_img).nil?
		property.texttype = Type.get(property.type_id).title
	end
	erb :search
end

load 'actions/route_region.rb'
load 'actions/route_location.rb'