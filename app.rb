$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rubygems'
require 'sinatra'
require 'sinatra/support'
require 'sinatra/reloader'
require 'lib/authorization'
require 'data_mapper'
require 'sass'

enable :sessions

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
	property :area_built,		String	
	property :price,			Integer
	property :sanad,			Boolean # Unsure what this option is in the real world, but defaults to false

	property :featured_img,		Integer
	property :slug,				String
	property :specs,			String
	property :bhk_count,		Integer
		
	property :viewcount,		Integer # automatically incremented every time instance pulled from db.
	property :created_at,		DateTime
	property :updated_at,		DateTime
	
	has n, :images
#	has n, :regions, :through => Resource
	belongs_to :location
	belongs_to :type
	belongs_to :state
	belongs_to :category
	
	def handle_upload(file)
		path = File.join(Dir.pwd, "/public/properties/images", file[:filename].downcase.gsub(" ", "-"))
		File.open(path, "wb") do |f|
			f.write(file[:tempfile].read)
		end
	end	
end

def to_currency(price)
	price.to_s.chars.to_a.reverse.each_slice(3).map(&:join).join(",").reverse
end

class Image
	include DataMapper::Resource
	
	property :id,			Serial
	property :product_id,	Integer
	property :url, 			String
	
	belongs_to :property
end

# Type class refers to "House", "Apartment", "Row Villa", etc.
class Type
	include DataMapper::Resource
	
	property :id,		Serial
	property :name,		String
	
	has n, :propertys
	
end

# Location refers to places like Anjuna, Mapusa, Panjim. Locations have many properties and have many regions.
class Location
	include DataMapper::Resource
	
	property :id,			Serial
	property :name,			String
	property :desc,			Text
	
	
	has n, :regions, :through => Resource
	has n, :propertys
	
end

# Region is a broad category, like North Goa, Coastal Region, City, etc. Regions have many locations.
class Region
	include DataMapper::Resource
	
	property :id,		Serial
	property :name,		String
	
	has n, :locations, :through => Resource
	
end

# Property can have one of two states: Sale or Rent
class State
	include DataMapper::Resource
	
	property :id,	Serial
	property :name,	String
	
	has n, :propertys
end

# Category refers to Commercial or Residential or Undeveloped
class Category
	include DataMapper::Resource
	
	property :id,	Serial
	property :name,	String
	
	has n, :propertys
end

DataMapper.auto_upgrade!

helpers do
	include Sinatra::Authorization
	def partial template
		erb template, :layout => false
	end
end

before do
	@page_title = "GoaPropertyCo"
	@body_class = "page"
	session[:properties] ||= {}
end

get '/reset' do
	DataMapper.auto_migrate!
	DataMapper.finalize
	
	tt = Type.first_or_create(:name => "Apartment")
	rr = Region.create(:name => "North Goa")
	rr = Region.create(:name => "South Goa")
	ss = State.first_or_create(:name => "Sale")
	ss = State.first_or_create(:name => "Rent")
	
	cc = Category.create(:name => "Residential")
	cc = Category.create(:name => "Commercial")
	cc = Category.create(:name => "Undeveloped")
end

get '/' do
	@body_class += " home"
	@page_title += " | Hassle-free Real Estate in Goa"
	@types = Type.all
	@regions = Region.all
	@states = State.all
	@categories = Category.all
	@properties = Property.all
	@region = Region.first
	@category = Category.get 1
	@state = State.get 2
	
	@properties.each do |property|
		property.featured_img = Image.get(property.featured_img).url unless Image.get(property.featured_img).nil?
	end
	erb :home
end

get '/about' do
	
	erb :about
end

get '/properties' do
	@properties = Property.all
	@regions = Region.all
	@region = Region.first
	@categories = Category.all
	@category = Category.first
	@states = State.all
	@state = State.first
	@body_class += " properties"
	@properties.each do |property|
		property.featured_img = Image.get(property.featured_img).url unless Image.get(property.featured_img).nil?
	end
	erb :properties
end

get '/property/new' do
	@regions = Region.all
	@locations = Location.all
	@types = Type.all
	@states = State.all
	@categories = Category.all
	@page_title += " | New Property"
	@body_class += " alt"
	erb :new
end

get '/property/:id/edit' do
	@property = Property.get(params[:id])
	@featured_img = Image.get(@property.featured_img).url unless Image.get(@property.featured_img).nil?
	@images = @property.images.all
	@regions = Region.all
	@locations = Location.all
	@types = Type.all
	@states = State.all
	@categories = Category.all
	@page_title += " | Edit Property"
	@body_class += " alt"
	erb :edit
end

get '/resource/new' do
	@locations = Location.all
	@regions = Region.all
	erb :new_resource
end

post '/update' do
	require_admin
	@property = Property.get(params[:property][:id])
	@update_params = params[:property]
	@featured = params[:featured_img]
	@gallDelete = params[:gallDels]
	@gallUpload = params[:gallUploads]

	unless @gallDelete.nil?
		@gallDelete.each_key { |key| Image.get(key).destroy }
	end

	unless @gallUpload.nil?
		params[:images].each do |image|
			@property.images.create({ :product_id => @property.id, :url => image[:filename].downcase.gsub(" ", "-") })
			@property.handle_upload(image)
		end
	end

	unless @featured.nil?
		@image = Image.get(@property.featured_img)
		@image.update({ :url => @featured[:filename].downcase.gsub(" ", "-") })
		@property.handle_upload(@featured)
	end

	if @property.update(@update_params)
		redirect "/property/#{@property.id}"
	else
		redirect "/property/#{@property.id}/edit"
	end
end

post '/create' do
	location = Location.get(params[:location][:id])
	type = Type.get(params[:type][:id])
	state = State.get(params[:state][:id])
	category = Category.get(params[:category][:id])
	property = Property.new(params[:property])
	
	location.propertys << property
	type.propertys << property
	state.propertys << property
	category.propertys << property
	
	
	property.slug = "#{property.title}-#{property.type.name}-#{property.location.name}"
	property.slug = property.slug.downcase.gsub(" ", "-")
	property.area = property.area.to_i
	property.price = property.price.to_i

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

post '/create/:newtype' do
	require_admin

	@create_type = params[:newtype]

	@save_val = ""

	case @create_type
	when "location"
		location = Location.create(params[:location])
		if !params[:region].nil?
			params[:region].each_value do |v|
				region = Region.get(v)
				location.regions << region
			end
		end
		@save_val = location
	when "region"
		region = Region.create(params[:region])
		if !params[:location].nil?
			params[:location].each_value do |v|
				location = Location.get(v)
				region.locations << location
			end
		end
		@save_val = region
	else
		raise "property"
	end
	
	if @save_val.save
		redirect '/resource/new'
	else
		redirect '/'
	end
end

get '/property/:id' do
	@body_class += " property"
	@property = Property.get params[:id]
	@images = @property.images[1..3]
	@property.featured_img = Image.get(@property.featured_img).url unless Image.get(@property.featured_img).nil?
	
	@regions = @property.location.regions
	@locations = @regions.locations
	
	
	# Similar properties pulls all property models which have the same LOCATION, are of the same TYPE (House/Apartment), in the same STATE (Buy/Rent), in the same CATEGORY (Commercial/Residential), minus the current property.
	
	@similar = @locations.propertys(:type_id => @property.type_id, :location_id => @property.location_id, :state_id => @property.state_id, :category_id => @property.category_id, :id.not => @property.id)
	@similar.each do |property|
		property.featured_img = Image.get(property.featured_img).url unless Image.get(property.featured_img).nil?
	end
	
	
	
	@categories = Category.all
	@category = Category.get(@property.category.id)
	@states = State.all
	@state = State.get(@property.state.id)
	@region = Region.get(@property.location.regions.first.id)
	
	session[:properties][@property.id] = @property.title
	
	viewed = []
	
	session[:properties].each_key {|key| viewed << key }
	@viewed = Property.all(:id => viewed)
	@viewed = @viewed[1..3]
	
	@viewed.each do |property|
		property.featured_img = Image.get(property.featured_img).url unless Image.get(property.featured_img).nil?
	end
	
	erb :property
end

get '/admin' do
	require_admin

	@properties = Property.all
	@regions = Region.all
	@locations = Location.all
	@types = Type.all
	@states = State.all
	@categories = Category.all

	erb :admin
end

get '/search' do
	@categories = Category.all
	@states = State.all
	@regions = Region.all	
	
	@category = Category.new(:name => "All")
	
	@region = Region.get(params[:search][:region_id])
	@state = State.get(params[:search][:state])
	@category = Category.get(params[:search][:category]) if params[:search][:category] != "All"
	
	@locations = @region.locations
	@properties = @locations.propertys(:state_id => @state.id) # with a sell or rent flag
	
	if @category.name != "All"
		@properties = @properties.all(:category_id => @category.id) # selecting "apartment", "House", etc
	end
	
	@locations = @properties.locations
	@location_ids = @locations.map(&:id)
	@types = @properties.types
	
	@properties.each do |property|
		property.featured_img = Image.get(property.featured_img).url unless Image.get(property.featured_img).nil?
		property.bhk_count ||= 3
		if property.bhk_count < 3
			property.bhk_count = property.bhk_count
		else
			property.bhk_count = 3
		end
	end
	erb :search
end

delete '/:delresource/destroy/:id' do
	require_admin
	@delresource = params[:delresource]
	@delval = ""
	case @delresource
	when "property"
		@delval = Property.get(params[:id])
	when "location"
		@delval = Location.get(params[:id])
	when "region"
		@delval = Region.get(params[:id])
	else
		raise "Nothing planned yet"
	end

	if @delval.destroy!
		redirect '/admin'
	else
		redirect '/'
	end
end

load 'actions/route_region.rb'
load 'actions/route_location.rb'