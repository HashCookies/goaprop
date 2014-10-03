require 'rubygems'
require 'sinatra'
require 'sinatra/support'
require 'sinatra/reloader'
require "#{Dir.pwd}/lib/authorization"
require 'data_mapper'
require 'mini_magick'
require 'sass'

enable :sessions
set :session_secret, 'x*DhdsHD83X'

get '/css/style.css' do
	content_type 'text/css', :charset => 'utf-8'
	scss(:"css/style")
end

configure :development do
	require 'dm-sqlite-adapter'
	DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/db.db")
end

configure :test do
	require 'dm-sqlite-adapter'
	DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/test.db")
end

# configure :production do
# 	require 'dm-sqlite-adapter'
# 	DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/db/db.db")
# end

configure :production do
	require 'mysql'
	require 'dm-mysql-adapter'
	DataMapper::setup(:default, "mysql://root:hash2014@127.0.0.1/goaprop")
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
	
	property :area,				Integer, :default => 0	# Written in a standard unit like "2000" that can be then interpreted. 
										# This value will not be shown to the user. Used for sorting.
	property :area_built,		Integer
	property :price,			Integer
	property :area_rate,		Integer
	property :sanad,			Boolean, :allow_nil => true # Some kind of status when dealing with unbuilt LAND type properties.

	property :featured_img,		Integer
	property :slug,				String
	property :specs,			String
	property :more_info,		Text
	property :bhk_count,		Integer

	property :status,			String
	property :age,				String
	property :brokerage,		String
	
	property :toil_attached,	Integer
	property :toil_nattached,	Integer
	property :furnishing,		String	# Do a <select> dropdown menu for these multiple choice String of properties.
										# Use the text string to add to database.
										# Make it default to empty, so if they're not selected they're not entered in the db.
										# We don't need to create separate models since we're not going to search based on these properties.
										# Even if we do we can catch them using the text search.
										
	property :floor,			String	
	property :lift,				Boolean, :allow_nil => true	
	property :water,			String
	property :electricity,		String
	property :zone,				String
	property :view,				String
	property :fsi,				String, :allow_nil => true
	property :field_notes,		Text

	property :layout_plan,		String
	property :master_plan,		String
		
	property :viewcount,		Integer # automatically incremented every time instance pulled from db.
	property :created_at,		DateTime
	property :updated_at,		DateTime
	property :is_active,		Boolean, :default => true
	property :is_premium,		Boolean, :default => false
	
	has n, :images
	belongs_to :location
	belongs_to :type
	belongs_to :state
	belongs_to :category
	
	def handle_upload(file, propertynumber)
		path = File.join(Dir.pwd, "/public/properties/images", propertynumber + "-" + file[:filename].downcase.gsub(" ", "-"))
		File.open(path, "wb") do |f|
			f.write(file[:tempfile].read)
		end
	end

	def handle_plan_upload(file, propertynumber, type)
		path = File.join(Dir.pwd, "/public/properties/images/plans", type, propertynumber + "-" + file[:filename].downcase.gsub(" ", "-"))
		File.open(path, "wb") do |f|
			f.write(file[:tempfile].read)
		end
	end
	
	def generate_thumb(file, propertynumber)
		path = File.join(Dir.pwd, "/public/properties/images", propertynumber + "-" + file[:filename].downcase.gsub(" ", "-"))
		image = MiniMagick::Image.open(path)
		image.resize "500x800"
		image.write Dir.pwd + "/public/properties/images/thumbs/" + propertynumber + "-" + file[:filename].downcase.gsub(" ", "-")
	end
	
	def classlist
		classlist = []
		classlist << self.location.name.downcase
		classlist << self.type.name.downcase.gsub(" ", "-")
		classlist << self.zone.downcase unless self.zone.nil?
		classlist << "bhk-#{self.bhk_count}" unless self.bhk_count.nil?
		classlist << "is-premium" if self.is_premium?
		classlist.join(" ")
	end
end

def to_currency(price)
	#price.to_s.chars.to_a.reverse.each_slice(3).map(&:join).join(",").reverse # Creates 100,000,000
	price.to_s.gsub(/(\d+?)(?=(\d\d)+(\d)(?!\d))(\.\d+)?/, "\\1,") # Creates 10,00,00,000
end

class Image
	include DataMapper::Resource
	
	property :id,			Serial
	property :url, 			String
	property :order_id,		Integer
	
	belongs_to :property
end

# Type class refers to "House", "Apartment", "Row Villa", etc.
class Type
	include DataMapper::Resource
	
	property :id,		Serial
	property :name,		String
	
	has n, :propertys
	
	def classlist(state_id, category_id, location_ids)
		classlist = []
		self.propertys(:state_id => state_id, :category_id => category_id, :location_id => location_ids).each do |pr|
			unless classlist.include? pr.location.name.downcase.gsub(" ", "-")
				classlist << pr.location.name.downcase.gsub(" ", "-")
			end
		end
		classlist.join(" ")
	end
	
end

# Location refers to places like Anjuna, Mapusa, Panjim. Locations have many properties and have many regions.
class Location
	include DataMapper::Resource
	
	property :id,			Serial
	property :name,			String
	property :desc,			Text
	
	
	has n, :regions, :through => Resource
	has n, :propertys
	
	def classlist(state_id, category_id)
		classlist = []
		self.propertys(:state_id => state_id, :category_id => category_id).each do |pr|
			unless classlist.include? pr.type.name.downcase.gsub(" ", "-")
				classlist << pr.type.name.downcase.gsub(" ", "-")
			end
		end
		classlist.join(" ")
	end
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

# Method to look for the type of request
set(:method) do |method|
	method = method.to_s.upcase
	condition { request.request_method == method }
end

# Based on previous method, this sniffs out the get methods and applies a :before filter
# Because we don't want the before filters on POST requests.
before :method => :get do
	@region = Region.first
	@category = Category.get 1
	@state = State.get 1
	
	@page_title = "GoaPropertyCo"
	@body_class = ""
	session[:properties] ||= {}
end


helpers do
	include Sinatra::Authorization
	def partial template
		erb template, :layout => false
	end
end

get '/reset' do
	require_admin
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
end

get '/setdefaultorder' do # run initially to populate the order_id field in images model
	require_admin
	@properties = Property.all
	@properties.each do |property|
		order_id = 0
		@images = property.images.all
		@images.each do |image|
			if (image.id == property.featured_img)
				image.update(:order_id => nil)
			else
				image.update(:order_id => order_id.to_i)
				order_id = order_id.to_i + 1
			end
		end
	end
end

get '/' do
	@body_class += " home"
	@page_title += " | Hassle-free Real Estate in Goa"
	
	erb :home
end

get '/about' do
	@body_class += " about"
	erb :about
end

get '/property/new' do
	require_admin
	
	@regions = Region.all
	@categories = Category.all
	
	@locations = Location.all
	@types = Type.all
	@states = State.all
	@page_title += " | New Property"
	@body_class += " alt"
	erb :new
end

get '/property/:id/edit' do
	require_admin
	@regions = Region.all
	@states = State.all
	@categories = Category.all
	
	@property = Property.get(params[:id])
	@featured_img = Image.get(@property.featured_img).url unless Image.get(@property.featured_img).nil?
	@images = @property.images.all(:id.not => @property.featured_img, :order => [ :order_id.asc ]) # Gallery Images minus Featured Image
	@locations = Location.all
	@types = Type.all
	@selected = 'selected="selected"'
	@page_title += " | Edit Property"
	@body_class += " alt"
	erb :edit
end

get '/property/:id/:slug' do
	@body_class += " property"
		
	# Getting the Property from the params of ID and setting it up for the view
	@property = Property.get params[:id]
	if (@property.is_active == true)
		@images = @property.images.all
		

		@image_grid = @property.images.all(:id.not => @property.featured_img, :order => [ :order_id.asc ], :limit => 3) # Gallery Images minus Featured Image

		# Required for the gallery fullscreen button
		@images_count = @images.count - 4 <= 0 ? nil : "#{@images.count - 4} more..."

		# Get the rest of the images for the gallery
		@hidden_images = @images.all(:id.not => @property.featured_img, :order => [ :order_id.asc ], :offset => 3, :limit => 15)
		
		# We've not changed the featured image url till now
		# because we require it to spell out the ID for the 
		# resources above.
		@property.featured_img = Image.get(@property.featured_img).url unless Image.get(@property.featured_img).nil?	
		
			
		# Similar properties pulls all property models which have the same LOCATION, are of the same TYPE (House/Apartment), in the same STATE (Buy/Rent), in the same CATEGORY (Commercial/Residential), minus the current property.
		@similar = @property.location.propertys(:type_id => @property.type_id, :state_id => @property.state_id, :category_id => @property.category_id, :id.not => @property.id)
		@similar.each do |property|
			property.featured_img = Image.get(property.featured_img).url unless Image.get(property.featured_img).nil?
		end
		
		# Variables for the search bar
		@category = Category.get(@property.category.id)
		@state = State.get(@property.state.id)
		@region = Region.get(@property.location.regions.first.id)
		
		# For the recently viewed items, pulling from the sessions cookie.
		session[:properties][@property.id] = @property.title
		viewed = []
		session[:properties].each_key {|key| viewed << key }
		@viewed = Property.all(:id => viewed)
		@viewed = @viewed[1..3]
		
		@viewed.each do |property|
			property.featured_img = Image.get(property.featured_img).url unless Image.get(property.featured_img).nil?
		end
		
		@page_title += " | #{@property.title} #{@property.type.name} in #{@property.location.name} for #{@property.state.name}"
		
		erb :property
	else
		redirect '/notfound'
	end
end

get '/resource/new' do
	@locations = Location.all
	@regions = Region.all
	@states = State.all
	@categories = Category.all

	erb :new_resource
end

get '/notfound' do
	erb :notfound
end

get '/viewable/:id/:switch' do
	@switch = params[:switch]
	@property = Property.get(params[:id])
	@viewable = @switch == '1' ? true : false
	if @property.update(:is_active => @viewable)
		redirect "/admin"
	else
		redirect "/admin"
	end
end

# get '/test' do
# 	require_admin
# 	@property = Property.get(1);
# 	@neworderid = Image.max(:order_id, :conditions => [ 'property_id = ?', @property.id ]) + 1
# 	raise @neworderid.to_s
# end

post '/update' do
	require_admin
	#raise params[:property][:water]
	@property = Property.get(params[:property][:id])
	@update_params = params[:property]
	@update_params.each_pair {|k,v| @update_params[k] = nil if v.empty? }
	@update_params[:area_built] = @update_params[:area_built].to_i unless @update_params[:area_built].nil?
	@update_params[:price] = @update_params[:price].downcase.gsub(",", "").to_i
	@update_params[:area] = @update_params[:area].to_i
	@update_params[:area_rate] = @update_params[:area_rate].to_i unless @update_params[:area_rate].nil?
	@update_params[:sanad] = params[:property][:sanad] == 'false' ? false : true unless @update_params[:sanad].nil?
	@update_params[:lift] = params[:property][:lift] == 'false' ? false : true unless @update_params[:lift].nil?
	@update_params[:is_active] = params[:property][:is_active] == 'false' ? false : true unless @update_params[:is_active].nil?
	@update_params[:toil_attached] = @update_params[:toil_attached].to_i unless @update_params[:toil_attached].nil?
	@update_params[:toil_nattached] = @update_params[:toil_nattached].to_i unless @update_params[:toil_nattached].nil?
	# @update_params[:floor] = @update_params[:floor].to_i

	@update_params[:layout_plan] = @property.id.to_s + "-" + params[:layout_plan][:filename].downcase.gsub(" ", "-") unless params[:layout_plan].nil?
	@update_params[:master_plan] = @property.id.to_s + "-" + params[:master_plan][:filename].downcase.gsub(" ", "-") unless params[:master_plan].nil?
	
	@featured = params[:featured_img]
	@gallDelete = params[:gallDels]
	@gallUpload = params[:gallUploads]
	@gallOrder = params[:gallOrder]
	@layout_plan = params[:layout_plan]
	@master_plan = params[:master_plan]
	

	@update_params[:slug] = (@update_params[:title].nil? ? "" : params[:property][:title] + "-") + Type.get(params[:property][:type_id]).name + "-in-" + Location.get(params[:property][:location_id]).name << "-for-" << State.get(params[:property][:state_id]).name
	@update_params[:slug] = @update_params[:slug].downcase.gsub(" ", "-")
	
	@update_params[:bhk_count] = @update_params[:bhk_count].to_i unless @update_params[:bhk_count].nil?

	@update_params[:area_built] = @update_params[:area_built].to_i unless @update_params[:area_built].nil?

	unless @gallOrder.nil?
		@gallOrder.each_pair do |k, v|
			@image = Image.get(k)
			@image.update(:order_id => v.to_i)
		end
	end

	unless @gallDelete.nil?
		@gallDelete.each_key { |key| Image.get(key).destroy }
	end
	
	unless @gallUpload.nil?
		params[:gallUploads].each do |image|
			# begin
				@neworderid = Image.max(:order_id, :conditions => [ 'property_id = ?', @property.id ]) + 1
				@property.images.create({ :property_id => @property.id, :url => @property.id.to_s + "-" + image[:filename].downcase.gsub(" ", "-"), :order_id => @neworderid.to_i })
				@property.handle_upload(image, @property.id.to_s)	
			# rescue Exception => e
			# 	puts e.resource.errors.inspect
			# 	raise 'error raised'
			# end
		end
	end

	unless @featured.nil?
		@image = Image.get(@property.featured_img)
		@image.update({ :url => @property.id.to_s + "-" + @featured[:filename].downcase.gsub(" ", "-") })
		@property.handle_upload(@featured, @property.id.to_s)
		@property.generate_thumb(@featured, @property.id.to_s)
	end

	
	@property.handle_plan_upload(@layout_plan, @property.id.to_s, "layout") unless @layout_plan.nil?

	@property.handle_plan_upload(@master_plan, @property.id.to_s, "master") unless @master_plan.nil?

	 # begin
		if @property.update(@update_params)
			redirect "/property/#{@property.id}/#{@property.slug}"
		else
			redirect "/property/#{@property.id}/edit"
		end
	 # rescue DataMapper::SaveFailureError => e
	 # 	puts e.resource.errors.inspect
	 # end
end



post '/create' do
	require_admin
	newparams = params[:property]
	newparams.each_pair {|k,v| newparams[k] = nil if v == "" }
	
	location = Location.get(params[:location][:id])
	type = Type.get(params[:type][:id])
	state = State.get(params[:state][:id])
	category = Category.get(params[:category][:id])
	property = Property.new(newparams)
	
	# Adding all the associations for the property (belongs to)
	location.propertys << property
	type.propertys << property
	state.propertys << property
	category.propertys << property
	
	# Sanitising some of the properties for saving to DataMapper.
	
	property.slug = (params[:property][:title].nil? ? "" : params[:property][:title] + "-") + "#{property.type.name}-in-#{property.location.name}-for-#{property.state.name}"
	property.slug = property.slug.downcase.gsub(" ", "-")
	property.area = property.area.to_i
	property.price = property.price.downcase.gsub(",", "").to_i
	
	property.area_built = property.area_built.to_i unless property.area_built.nil?
	property.area_rate = property.area_rate.to_i unless property.area_rate.nil?

	# Sanitising BHK count. Checks if params has a "" (empty) string. If true, it's nil. Else, it's whatitis.to_i
	property.bhk_count = property.bhk_count.to_i unless property.bhk_count.nil?
	property.toil_attached =  property.toil_attached.to_i unless property.toil_attached.nil?
	property.toil_nattached = property.toil_nattached.to_i unless property.toil_nattached.nil?
	property.is_active = params[:property][:is_active] == 'true' ? true : false unless property.is_active.nil?
	
	if property.save			
		if !params[:images].nil?
			order_id = 0
			params[:images].each do |image|
				property.images.create({:url => property.id.to_s + "-" + image[:filename].downcase.gsub(" ", "-"), :order_id => order_id})
				property.handle_upload(image, property.id.to_s)
				order_id = order_id + 1 
			end
		end
		
		if !params[:featured].nil?
			@featured = property.images.create({:url => property.id.to_s + "-" + params[:featured][:filename].downcase.gsub(" ", "-") })
			property.handle_upload(params[:featured], property.id.to_s)
			property.update({ :featured_img => @featured.id })
			
			property.generate_thumb(params[:featured], property.id.to_s)
		end
		

		if !params[:layout_plan].nil?
			property.handle_plan_upload(params[:layout_plan], property.id.to_s, "layout")
			property.update(:layout_plan => property.id.to_s + "-" + params[:layout_plan][:filename].downcase.gsub(" ", "-"))
		end

		if !params[:master_plan].nil?
			property.handle_plan_upload(params[:master_plan], property.id.to_s, "master")
			property.update(:master_plan => property.id.to_s + "-" + params[:master_plan][:filename].downcase.gsub(" ", "-"))
		end
		
		redirect "/property/#{property.id}/#{property.slug}"
	else
		redirect '/properties'
	end
end

get '/admin' do	
	require_admin
	
	@regions = Region.all
	@states = State.all
	@categories = Category.all
	
	@body_class += " admin"
	@properties = Property.all
	@locations = Location.all
	@types = Type.all
	@properties.each do |property|
		if !Image.get(property.featured_img).nil?
			property.featured_img = Image.get(property.featured_img).url
		else
			property.featured_img = "gpc-default-thumb.jpg"
		end
		# property.featured_img = Image.get(property.featured_img).url unless Image.get(property.featured_img).nil?
	end

	erb :admin
end

get '/search' do
	@category = Category.new(:name => "All")
	
	@region = Region.get(params[:search][:region_id])
	@state = State.get(params[:search][:state])
	@category = Category.get(params[:search][:category]) if params[:search][:category] != "All"
	
	@locations = @region.locations(:order => [:name.asc])
	@properties = @locations.propertys(:state_id => @state.id, :is_active => true, :order => [:is_premium.desc]) # with a sell or rent flag
	
	if @category.name != "All"
		@properties = @properties.all(:category_id => @category.id) # selecting "Residential", "Commercial", etc
	end
	
	@location_ids = @locations.map(&:id) # For masonry filters
	@types = @properties.types
	
	@properties.each do |property|
		if !Image.get(property.featured_img).nil?
			property.featured_img = Image.get(property.featured_img).url
		else
			property.featured_img = "gpc-default-thumb.jpg"
		end
	end
	erb :search
end

delete '/:delresource/destroy/:id' do
	require_admin
	@delresource = params[:delresource]
	@delval = ""
	@delvalimg = ""
	case @delresource
	when "property"
		@delval = Property.get(params[:id])
		@images = Image.all(:property_id => params[:id])
		@images.each do |image|
			image.destroy!
		end
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
		@body = params[:inquiry][:body] << "<br />Inquiry Sent by: " << params[:inquiry][:name] << "<br />Phone: " << params[:inquiry][:phone] << "<br />Email: " << params[:inquiry][:email]
	when "leasesell"
		@mailFrom = params[:leasesell][:name]
		@subject = "Property for " << params[:leasesell][:state]
		@description = params[:leasesell][:description] == "" ? "" : "<br />Property described as: " << params[:leasesell][:description]
		@body = params[:leasesell][:name] << " has a property for " << params[:leasesell][:state] << "<br /> Who can be contacted on Phone: " << params[:leasesell][:phone] << " and Email: " << params[:leasesell][:email] << @description
	when "friendmail"
		@mailFrom = params[:friendmail][:frommail]
		@mailTo = params[:friendmail][:tomail]
		@subject = params[:friendmail][:name] + " looked up a property for you"
		@body = params[:friendmail][:mailbody] << "<br />Regards,<br />" << params[:friendmail][:name]
		# @body = params[:friendmail][:name] << " has a property for you at Goa Property Co<br /> Please check the following link: " << request.base_url << "/property/" << params[:friendmail][:propID] << "<br />Regards,<br />Goa Property Co. "
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
	@page_title += " | Sell or Lease Your Property"
	erb :sell
end

load 'actions/route_region.rb'
load 'actions/route_location.rb'
load 'actions/route_type.rb'
