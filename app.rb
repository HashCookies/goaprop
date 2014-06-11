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

DataMapper::Property::String.length(255)

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
	property :area_built,		String
	property :featured_img,		Integer
	property :slug,				String
	
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
	belongs_to :region
	
	
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
	property :title,	String
	
	has n, :propertys
	
end

class Location
	include DataMapper::Resource
	
	property :id,			Serial
	property :name,			String
	
	belongs_to :region
	has n, :propertys
end

class Region
	include DataMapper::Resource
	
	property :id,		Serial
	property :name,		String
	
	has n, :propertys
	has n, :locations
end

DataMapper.auto_upgrade!

before do
	@page_title = "GoaPropertyCo"
end

get '/' do
	@properties = Property.all
	@properties.each do |property|
		property.featured_img = Image.get(property.featured_img).url unless Image.get(property.featured_img).nil?
	end
	erb :home
end

get '/properties' do
	@properties = Property.all
	@properties.each do |property|
		property.featured_img = Image.get(property.featured_img).url unless Image.get(property.featured_img).nil?
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
	@property = Property.new(params[:property])
	@property.slug = @property.title.downcase.gsub(" ", "-")
	@featured_img = params[:featured]
	
	if @property.save	
		
		params[:images].each do |image|
			@property.images.create({ :property_id => @property.id, :url => image[:filename].downcase.gsub(" ", "-") })
			@property.handle_upload(image)
		end
		
		if !params[:featured].nil?
			@featured = @property.images.create({ :property_id => @property.id, :url => params[:featured][:filename].downcase.gsub(" ", "-") })
			@property.handle_upload(params[:featured])
			@property.update({ :featured_img => @featured.id })
		end
		
		redirect "/property/#{@property.id}"
	else
		redirect '/properties'
	end
end

get '/property/:id' do
	@property = Property.get params[:id]
	@images = @property.images
	@property.featured_img = Image.get(@property.featured_img).url
	erb :property
end

get '/properties' do
	@properties = Property.all
end


get '/region/new' do
	erb :new_region
end

post '/region/create' do
	@region = Region.new(params[:region])
	if @region.save
		redirect '/region/new'
	else
		redirect '/'
	end
end