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

configure :production do
	require 'dm-sqlite-adapter'
	DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/db/db.db")
end

# configure :production do
# 	require 'mysql'
# 	require 'dm-mysql-adapter'
#   DataMapper::setup(:default, "mysql://root:hash2014@127.0.0.1/goaprop")
# end

DataMapper::Property::String.length(255)
DataMapper::Model.raise_on_save_failure = true 

class Main < Sinatra::Base
  register Sinatra::Numeric
end

class Property
	include DataMapper::Resource
	
#<<<<<<< HEAD
	# property :id,					Serial
	# property :title,				String
	
	# property :area,					Integer	# Written in a standard unit like "2000" that can be then interpreted. 
	# 										# This value will not be shown to the user. Used for sorting.
	# property :area_built,			Integer, :default => 0	
	# property :price,				Integer
	# property :rate,					Integer
	
	# property :featured_img,			Integer
	# property :slug,					String
	# property :specs,				String
	# property :bhk_count,			Integer

	# # Property specifications
	# property :bedrooms,				Integer
	# property :toilets_attached,		Integer
	# property :toilets_nonattached,	Integer
	# property :floor,				Integer
	# property :lift,					Boolean, :default => false
	# property :sanad,				Boolean, :default => false
	# property :electricity,			Integer
	# property :view,					String
	# property :fsi,					String
	
	# property :viewcount,			Integer # automatically incremented every time instance pulled from db.
	# property :created_at,			DateTime
	# property :updated_at,			DateTime
#=======
	property :id,				Serial
	property :title,			String
	
	property :area,				Integer	# Written in a standard unit like "2000" that can be then interpreted. 
										# This value will not be shown to the user. Used for sorting.
	property :area_built,		Integer	
	property :price,			Integer
	property :area_rate,		Integer
	property :sanad,			Boolean # Unsure what this option is in the real world, but defaults to false

	property :featured_img,		Integer
	property :slug,				String
	property :specs,			String
	property :bhk_count,		Integer
	
	property :toil_attached,	Integer # form field
	property :toil_nattached,	Integer #form field
	property :furnishing,		String	# Do a <select> dropdown menu for these multiple choice String of properties.
										# Use the text string to add to database.
										# Make it default to empty, so if they're not selected they're not entered in the db.
										# We don't need to create separate models since we're not going to search based on these properties.
										# Even if we do we can catch them using the text search.
										
	property :floor,			String	
	property :lift,				Boolean	
	property :water,			String
	property :electricity,		String
	property :zone,				String
	property :view,				String
	property :fsi,				Integer
		
	property :viewcount,		Integer # automatically incremented every time instance pulled from db.
	property :created_at,		DateTime
	property :updated_at,		DateTime
#>>>>>>> 0a05a5aec56600f09d5e39038d635d4d7fc93393
	
	has n, :images
#	has n, :regions, :through => Resource
	# belongs_to :furnishing
	# belongs_to :watersupply, :required => false
	# belongs_to :zone, :required => false
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

# class Furnishing
# 	include DataMapper::Resource

# 	property :id,		Serial
# 	property :name,		String

# 	has n, :propertys
# 	#belongs_to :property
# end

# class Watersupply
# 	include DataMapper::Resource

# 	property :id, 		Serial
# 	property :name, 	String

# 	has n, :propertys
# end

# class Zone
# 	include DataMapper::Resource

# 	property :id,		Serial
# 	property :name,		String

# 	has n, :propertys
# end

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
	@hide_link = false
	session[:properties] ||= {}
end


get '/reset' do
	DataMapper.auto_migrate!
	DataMapper.finalize
	
	tt = Type.first_or_create(:name => "Apartment")
	tt = Type.first_or_create(:name => "House")
	#tt = Type.first_or_create(:name => "Land")

	rr = Region.create(:name => "North Goa")
	rr = Region.create(:name => "South Goa")

	ss = State.first_or_create(:name => "Sale")
	ss = State.first_or_create(:name => "Rent")
	
	cc = Category.create(:name => "Residential")
	cc = Category.create(:name => "Commercial")
	cc = Category.create(:name => "Land")

	ff = Furnishing.first_or_create(:name => "Not Applicable")
	ff = Furnishing.first_or_create(:name => "Unfurnished")
	ff = Furnishing.first_or_create(:name => "Semi")
	ff = Furnishing.first_or_create(:name => "Basic")
	ff = Furnishing.first_or_create(:name => "Furnished")

	zz = Zone.first_or_create(:name => "Not Applicable")
	zz = Zone.first_or_create(:name => "Settlement")
	zz = Zone.first_or_create(:name => "Orchard")
	zz = Zone.first_or_create(:name => "Agriculture")

	ww = Watersupply.first_or_create(:name => "Not Applicable")
	ww = Watersupply.first_or_create(:name => "Well")
	ww = Watersupply.first_or_create(:name => "Bore-Well")
	ww = Watersupply.first_or_create(:name => "Municipality")
end

# get '/newcolumns' do
# 	require_admin

# 	ff = Furnishing.first_or_create(:name => "Not Applicable")
# 	ff = Furnishing.first_or_create(:name => "Unfurnished")
# 	ff = Furnishing.first_or_create(:name => "Semi")
# 	ff = Furnishing.first_or_create(:name => "Basic")
# 	ff = Furnishing.first_or_create(:name => "Furnished")

# 	zz = Zone.first_or_create(:name => "Not Applicable")
# 	zz = Zone.first_or_create(:name => "Settlement")
# 	zz = Zone.first_or_create(:name => "Orchard")
# 	zz = Zone.first_or_create(:name => "Agriculture")

# 	ww = Watersupply.first_or_create(:name => "Not Applicable")
# 	ww = Watersupply.first_or_create(:name => "Well")
# 	ww = Watersupply.first_or_create(:name => "Bore-Well")
# 	ww = Watersupply.first_or_create(:name => "Municipality")
	
# 	@properties = Property.all(:furnishing_id => nil, :watersupply_id => nil, :zone_id => nil)
# 	@properties.each do |property|
# 		property.update(:furnishing_id => 1, :watersupply_id => 1, :zone_id => 1, :sanad => 0)
# 	end
# 	redirect "/"
# end

get '/' do
	@body_class += " home"
	@page_title += " | Hassle-free Real Estate in Goa"
	@regions = Region.all
	@states = State.all
	@categories = Category.all
	@region = Region.first
	@category = Category.get 1
	@state = State.get 2
	
	erb :home
end

get '/about' do
	@body_class += " about"
	@regions = Region.all
	@locations = Location.all
	@types = Type.all
	@states = State.all
	@categories = Category.all
	@region = Region.first
	@category = Category.get 1
	@state = State.get 2
	erb :about
end

get '/property/new' do
	@regions = Region.all
	@locations = Location.all
	@types = Type.all
	@states = State.all
	# @categories = Category.all
	# @furnishings = Furnishing.all
	# @watersupplies = Watersupply.all
	@zones = Zone.all
	@region = Region.first
	@category = Category.get 1
	@state = State.get 2
	@page_title += " | New Property"
	@body_class += " alt"
	erb :new
end

get '/property/:id/edit' do
	require_admin
	@property = Property.get(params[:id])
	@featured_img = Image.get(@property.featured_img).url unless Image.get(@property.featured_img).nil?
	@images = @property.images.all(:id.not => @property.featured_img) # Gallery Images minus Featured Image
	@regions = Region.all
	@locations = Location.all
	@types = Type.all
	@states = State.all
	# @furnishings = Furnishing.all
	# @watersupplies = Watersupply.all
	# @zones = Zone.all
	@categories = Category.all
	@page_title += " | Edit Property"
	@body_class += " alt"
	@region = Region.first
	@category = Category.get 1
	@state = State.get 2
	erb :edit
end

get '/property/:id' do
	@body_class += " property"
		
	# Getting the Property from the params of ID and setting it up for the view
	@property = Property.get params[:id]
	@images = @property.images.all(:id.not => @property.featured_img, :limit => 3) # Gallery Images minus Featured Image
	@property.featured_img = Image.get(@property.featured_img).url unless Image.get(@property.featured_img).nil?
		
	# Similar properties pulls all property models which have the same LOCATION, are of the same TYPE (House/Apartment), in the same STATE (Buy/Rent), in the same CATEGORY (Commercial/Residential), minus the current property.
	@similar = @property.location.propertys(:type_id => @property.type_id, :state_id => @property.state_id, :category_id => @property.category_id, :id.not => @property.id)
	@similar.each do |property|
		property.featured_img = Image.get(property.featured_img).url unless Image.get(property.featured_img).nil?
	end
	
	# Variables for the search bar
	@categories = Category.all
	@category = Category.get(@property.category.id)
	@states = State.all
	@state = State.get(@property.state.id)
	@region = Region.get(@property.location.regions.first.id)
	@regions = Region.all # reset the regions to ALL which are at the top only of the current location's regions.
	
	# For the recently viewed items, pulling from the sessions cookie.
	session[:properties][@property.id] = @property.title
	viewed = []
	session[:properties].each_key {|key| viewed << key }
	@viewed = Property.all(:id => viewed)
	@viewed = @viewed[1..3]
	
	@page_title += " | #{@property.title} #{@property.type.name} in #{@property.location.name} for #{@property.state.name}"
	
	erb :property
end

get '/resource/new' do
	@locations = Location.all
	@regions = Region.all
	@region = Region.first
	@category = Category.get 1
	@state = State.get 2
	erb :new_resource
end

post '/update' do
	require_admin
	@property = Property.get(params[:property][:id])
	@update_params = params[:property]
	@update_params[:area_built] = @update_params[:area_built].downcase.gsub(" sq mt", "")
	@update_params[:area_built] = @update_params[:area_built].downcase.gsub(" sq mts", "")
	@update_params[:price] = @update_params[:price].downcase.gsub(",", "")
	@update_params[:sanad] = params[:property][:sanad] == 'false' ? false : true
	@update_params[:lift] = params[:property][:lift] == 'false' ? false : true
	# @update_params[:furnishing_id] = @update_params[:furnishing_id].to_i
	# @update_params[:watersupply_id] = @update_params[:watersupply_id].to_i
	# @update_params[:zone_id] = @update_params[:zone_id].to_i
	# @update_params[:electricity] = @update_params[:electricity].to_i
	# @update_params[:bedrooms] = @update_params[:bedrooms].to_i
	# @update_params[:toilets_attached] = @update_params[:toilets_attached].to_i
	# @update_params[:toilets_nonattached] = @update_params[:toilets_nonattached].to_i
	# @update_params[:floor] = @update_params[:floor].to_i
	
	@featured = params[:featured_img]
	@gallDelete = params[:gallDels]
	@gallUpload = params[:gallUploads]

	if @update_params[:category_id] == "3"
		@update_params[:bhk_count] = 0
	else
		@update_params[:bhk_count] = @update_params[:bhk_count].to_i
	end

	if @update_params[:area_built] == ''
		@update_params[:area_built] = 0
	else
		@update_params[:area_built] = @update_params[:area_built].to_i
	end

	#raise params[:property][:area_built].to_s

	unless @gallDelete.nil?
		@gallDelete.each_key { |key| Image.get(key).destroy }
	end
	
	unless @gallUpload.nil?
		params[:gallUploads].each do |image|
			# begin
				@property.images.create({ :property_id => @property.id, :url => image[:filename].downcase.gsub(" ", "-") })
				@property.handle_upload(image)	
			# rescue Exception => e
			# 	puts e.resource.errors.inspect
			# 	raise 'error raised'
			# end
		end
	end

	unless @featured.nil?
		@image = Image.get(@property.featured_img)
		@image.update({ :url => @featured[:filename].downcase.gsub(" ", "-") })
		@property.handle_upload(@featured)
	end

	 begin
		if @property.update(@update_params)
			redirect "/property/#{@property.id}"
		else
			redirect "/property/#{@property.id}/edit"
		end
	 rescue DataMapper::SaveFailureError => e
	 	puts e.resource.errors.inspect
	 end
end



post '/create' do
	location = Location.get(params[:location][:id])
	type = Type.get(params[:type][:id])
	state = State.get(params[:state][:id])
	category = Category.get(params[:category][:id])
	# furnishing = Furnishing.get(params[:furnishing][:id])
	# watersupply = Watersupply.get(params[:watersupply][:id])
	# zone = Zone.get(params[:zone][:id])
	property = Property.new(params[:property])
	
	location.propertys << property
	type.propertys << property
	state.propertys << property
	category.propertys << property
	# furnishing.propertys << property
	# watersupply.propertys << property
	# zone.propertys << property
	
	property.slug = "#{property.title}-#{property.type.name}-#{property.location.name}"
	property.slug = property.slug.downcase.gsub(" ", "-")
	property.area = property.area.to_i
	property.price = property.price.to_i
	property.area_built = property.area_built.downcase.gsub(" sq mt", "")
	property.area_built = property.area_built.downcase.gsub(" sq mts", "")
	
	if params[:category][:id] == "3"
		property.bhk_count = 0
	else
		property.bhk_count = property.bhk_count.to_i
	end
	
	if property.area_built == ''
		property.area_built = 0
	else
		property.area_built = property.area_built.to_i
	end	

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

# post '/create/:newtype' do
# 	require_admin

# 	@create_type = params[:newtype]

# 	@save_val = ""

# 	case @create_type
# 	when "location"
# 		location = Location.create(params[:location])
# 		if !params[:region].nil?
# 			params[:region].each_value do |v|
# 				region = Region.get(v)
# 				location.regions << region
# 			end
# 		end
# 		@save_val = location
# 	when "region"
# 		region = Region.create(params[:region])
# 		if !params[:location].nil?
# 			params[:location].each_value do |v|
# 				location = Location.get(v)
# 				region.locations << location
# 			end
# 		end
# 		@save_val = region
# 	when "type"
# 		type = Type.create(params[:type])
# 		@save_val = type
# 	else
# 		raise "property"
# 	end
	
# 	if @save_val.save
# 		redirect '/admin'
# 	else
# 		redirect '/'
# 	end
# end

get '/admin' do
	require_admin
	@body_class += " admin"
	@properties = Property.all
	@regions = Region.all
	@locations = Location.all
	@locations.each do |location|
		location.propertys.each do |property|
			property.featured_img = property.images.get(property.featured_img).url unless property.images.get(property.featured_img).nil?
		end
	end
	@types = Type.all
	@states = State.all
	@categories = Category.all
	@region = Region.first
	@category = Category.get 1
	@state = State.get 2

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
		@properties = @properties.all(:category_id => @category.id) # selecting "Residential", "Commercial", etc
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

post '/send-inquiry/:for' do
	require 'pony'
	@mailTo = "alistair.rodrigues@gmail.com"
	@mailFor = params[:for]
	@mailFrom = ""
	@subject = ""
	@body = ""
	case @mailFor
	when "inquiry"
		@mailFrom = params[:inquiry][:name]
		@subject = "Inquiry for property"
		@body = params[:inquiry][:body] << "</br>Inquiry Sent by: " << params[:inquiry][:email]
	when "leasesell"
		@mailFrom = params[:leasesell][:name]
		@subject = "Property for " << params[:leasesell][:state]
		@description = params[:leasesell][:description] == "" ? "" : "<br />Property described as: " << params[:leasesell][:description]
		@body = params[:leasesell][:name] << " has a property for " << params[:leasesell][:state] << "<br /> Who can be contacted on Phone: " << params[:leasesell][:phone] << " and Email: " << params[:leasesell][:email] << @description
	when "friendmail"
		@mailFrom = params[:friendmail][:frommail]
		@mailTo = params[:friendmail][:tomail]
		@subject = params[:friendmail][:name] + " looked up a property for you"
		@body = params[:friendmail][:name] << " has a property for you at Goa Property Co<br /> Please check the following link: " << request.base_url << "/property/" << params[:friendmail][:propID] << "<br />Regards,<br />Goa Property Co. "
  	else
  		@mailFrom = params[:callback][:name]
  		@subject = "Callback Request"
		@body = "Callback Request Sent by: " << params[:callback][:name] << "<br />No: " << params[:callback][:phone] << "<br />Call Between: " << params[:callback][:timing]
	end
	Pony.mail(
		:from => @mailFrom,
		:to => @mailTo,
		:subject => @subject,
		:headers => { 'Content-Type' => 'text/html' },
		:body => @body,
		:via => :smtp,
		:via_options => {
			:address              => 'smtp.sendgrid.net', 
	    	:port                 => '587', 
	    	:user_name            => 'hashcookies', 
	    	:password             => 'Nor1nderchqMudi', 
	    	:authentication       => :plain
		}
	)
	redirect '/'
end

get '/sell-lease' do
	@body_class += " leasesell"
	@regions = Region.all
	@states = State.all
	@categories = Category.all
	@region = Region.first
	@category = Category.get 1
	@state = State.get 2
	
	erb :sell
end

load 'actions/route_region.rb'
load 'actions/route_location.rb'
load 'actions/route_type.rb'
