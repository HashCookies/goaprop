require 'rubygems'
require 'sinatra'
require 'sinatra/json'
require 'sinatra/support'
require 'sinatra/reloader'
require 'json'
require "#{Dir.pwd}/lib/authorization"
require 'data_mapper'
require 'mini_magick'
require 'sass'
require 'sinatra/form_helpers'
require 'tumblr_client'
require 'oauth'

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

configure :production do
	require 'mysql'
	require 'dm-mysql-adapter'
	DataMapper::setup(:default, "mysql://root:hash2014@127.0.0.1/goaprop")
end

DataMapper::Property::String.length(255)
DataMapper::Model.raise_on_save_failure = true 


class Main < Sinatra::Base
  register Sinatra::Numeric
  helpers Sinatra::FormHelpers
end

class Property
	include DataMapper::Resource
	
	property :id,				Serial
	property :title,			String, :length => 500
	
	property :area,				Integer

	property :area_built,		Integer
	property :price,			Integer
	property :area_rate,		Boolean
	property :sanad,			Boolean, :allow_nil => true

	property :featured_img,		Integer
	property :slug,				String
	property :specs,			String
	property :more_info,		Text
	property :bhk_count,		Integer

	property :status,			Integer, :default => 4 # Re-sale (1) , Ready Possession (2), Under Construction (3)
	property :age,				String
	
	property :toil_attached,	Integer
	property :toil_nattached,	Integer
	property :furnishing,		String											
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
		
	property :created_at,		DateTime
	property :updated_at,		DateTime
	property :is_active,		Boolean, :default => true
	property :is_premium,		Boolean, :default => false
	property :priority,			Integer, :default => 4
	
	has n, 	   :images, :constraint => :destroy
	belongs_to :location
	belongs_to :type
	belongs_to :state
	belongs_to :category
	
	def handle_upload(file, propertynumber)
		path = File.join(Dir.pwd, "/public/properties/images", propertynumber + "-" + file[:filename].downcase.gsub(" ", "-"))
		if !File.exists?(path)
			File.open(path, "wb") do |f|
				f.write(file[:tempfile].read)
			end
		end
	end

	def handle_plan_upload(file, propertynumber, type)
		path = File.join(Dir.pwd, "/public/properties/images/plans", type, propertynumber + "-" + file[:filename].downcase.gsub(" ", "-"))
		if !File.exists?(path)
			File.open(path, "wb") do |f|
				f.write(file[:tempfile].read)
			end
		end
	end
	
	def generate_thumb(file, propertynumber)
		path = File.join(Dir.pwd, "/public/properties/images", propertynumber + "-" + file[:filename].downcase.gsub(" ", "-"))
		thumbpath = File.join(Dir.pwd, "/public/properties/images/thumbs", propertynumber + "-" + file[:filename].downcase.gsub(" ", "-"))
		if !File.exists?(thumbpath)
			image = MiniMagick::Image.open(path)
			image.resize "500x800"
			image.write thumbpath #Dir.pwd + "/public/properties/images/thumbs/" + propertynumber + "-" + file[:filename].downcase.gsub(" ", "-")
		end 
	end
	
	def classlist
		classlist = []
		classlist << self.location.name.downcase
		classlist << self.type.name.downcase.gsub(" ", "-")
		classlist << self.zone.downcase 						unless self.zone.nil?
		classlist << "bhk-#{self.bhk_count}"
		classlist << "is-premium" 								if self.is_premium?
		classlist << self.prop_status.downcase.gsub(" ", "-")
		classlist.join(" ")
	end
	
	def prop_status
		if self.status == 1
			"Re-sale"
		elsif self.status == 2
			"Ready Possession"
		elsif self.status == 3
			"Under Construction"
		else
			"na"
		end
	end
	
	def brokerage
		return "2%" 	 if self.state_id == 1 # sale
		return "1 month" if self.state_id == 2 # rent
	end
	
	def is_active=(switch)
		if switch == "on" || switch == "true"
			super true
		else
			super false
		end
	end

	def is_premium=(switch)
		if switch == "on" || switch == "true"
			super true
		else
			super false
		end
	end
	
	def area_rate=(switch)
		if switch == "on" || switch == "true"
			super true
		else
			super false
		end
	end
	
	def show_area_rate
		return self.price / self.area if self.price && self.area
		"NA"
	end

	def price=(amount)
		super amount.gsub(",", "")
	end
	
	def show_price
		return self.price if !self.price.nil?
		"Price on Request"
	end
	
	def full_title
		full_title = ""
		full_title = full_title + "<span class='prop-string'>#{self.title}</span> " if self.title
		full_title = 
			full_title + "<span class='prop-string'>#{self.type.name}</span> <span class='smaller'>in <span class='prop-string'>#{self.location.name}</span></span>"
	end
	
	def full_title_extended
		self.full_title + " <span class='smaller'>for <span class='prop-string'>#{self.state.name}</span></span>"
	end
	
	def full_title_text
		full_title_text = ""
		full_title_text = full_title_text + "#{self.title} " if self.title
		full_title_text = full_title_text + "#{self.type.name} in #{self.location.name} for #{self.state.name}"
	end
	
	def featured_img_url
		if !self.featured_img.nil?
			Image.get(self.featured_img).url
		else
			'gpc-default-thumb.jpg'
		end
	end
	
	def slug
		slug = ""
		slug = slug + "#{self.title} " if self.title
		slug = slug + "#{self.type.name} in #{self.location.name} for #{self.state.name}"
		slug.downcase.gsub(" ", "-")
	end	
end

def to_currency(price, state)
	price = price.to_s.gsub(/(\d+?)(?=(\d\d)+(\d)(?!\d))(\.\d+)?/, "\\1,") # Creates 10,00,00,000
	if state == 2 # for RENT
		price + " / mo"
	else
		price
	end	
end

def simple_format(text)
	text.gsub(/^(.*)$/, '<p>\1</p>')
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

	session[:properties] ||= {}
end


helpers do
	include Sinatra::Authorization
	def partial template
		erb template, :layout => false
	end
	
	def page_title(title="")
		if title.nil?
			"Goa Property Co"
		else
			"Goa Property Co | #{title}"
		end
	end
	
	def body_class(class_array=[])
		body_class = []
		body_class << class_array
		body_class.join(" ")
	end
end

get '/reset' do
	require_admin
	DataMapper.auto_migrate!
	DataMapper.finalize
	
	Type.first_or_create(:name => "Apartment")
	Type.first_or_create(:name => "House")
	#tt = Type.first_or_create(:name => "Land")

	Region.create(:name => "North Goa")
	Region.create(:name => "South Goa")

	State.first_or_create(:name => "Sale")
	State.first_or_create(:name => "Rent")
	
	Category.create(:name => "Residential")
	Category.create(:name => "Commercial")
	Category.create(:name => "Land")
	
end

get '/' do
	@classes = ['home']
	@title = "Hassle-free Real Estate in Goa"
	
	erb :home
end

get '/about' do
	@classes = ['about']
	@title = "Our Services"
	
	erb :about
end

get '/property/new' do
	require_admin
	
	@classes = ['alt']

	@property = Property.new
	@images = @property.images
	
	@regions = Region.all
	@categories = Category.all
	
	@locations = Location.all
	@types = Type.all
	@states = State.all
	@title = "New Property"

	erb :new
end

get '/property/:id/edit' do
	require_admin
	@regions = Region.all
	@states = State.all
	@categories = Category.all
	
	@property = Property.get(params[:id])
	@images = @property.images.all(:id.not => @property.featured_img, :order => [ :order_id.asc ]) # Gallery Images minus Featured Image
	@locations = Location.all
	@types = Type.all
	@title = "Editing #{@property.full_title_text}"
	erb :edit
end

get '/property/:id/:slug' do
	@classes = ['property']
		
	# Getting the Property from the params of ID and setting it up for the view
	@property = Property.get params[:id]
	
	if @property.is_active
		@images = @property.images.all

		@image_grid = 
			@property.images.all(
				:id.not => @property.featured_img, 
				:order => [ :order_id.asc ], 
				:limit => 3) # Gallery Images minus Featured Image

		# Required for the gallery fullscreen button
		@images_count = @images.count - 4 <= 0 ? nil : "#{@images.count - 4} more..."

		# Get the rest of the images for the gallery
		@hidden_images = 
			@images.all(
				:id.not => @property.featured_img, 
				:order => [ :order_id.asc ], 
				:offset => 3, 
				:limit => 15)
		
			
		# Similar properties pulls all property models which have the same LOCATION, are of the same TYPE (House/Apartment), in the same STATE (Buy/Rent), in the same CATEGORY (Commercial/Residential), minus the current property.
		@similar =
			@property.location.propertys(
				:type_id => @property.type_id, 
				:state_id => @property.state_id, 
				:category_id => @property.category_id, 
				:id.not => @property.id)
		
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
		
	
		@title = @property.full_title_text
		
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

post '/properties' do
	require_admin
	newparams = params[:property]
	newparams.each_pair {|k,v| newparams[k] = nil if v == "" }

	newparams[:is_premium] = "" unless !newparams[:is_premium].nil? # if no value is present for is_premium set false
	newparams[:is_active] = "" unless !newparams[:is_active].nil? # if no value is present for is_active set false
	
	location = Location.get(params[:property][:location_id])
	type = Type.get(params[:property][:type_id])
	state = State.get(params[:property][:state_id])
	category = Category.get(params[:property][:category_id])
	
	@property = Property.new(newparams)
	
	# Adding all the associations for the property (belongs to)
	location.propertys << @property
	type.propertys << @property
	state.propertys << @property
	category.propertys << @property
	
	if @property.save			
		if !params[:images].nil?
			order_id = 0
			params[:images].each do |image|
				@property.images.create({:url => @property.id.to_s + "-" + image[:filename].downcase.gsub(" ", "-"), :order_id => order_id})
				@property.handle_upload(image, @property.id.to_s)
				order_id = order_id + 1 
			end
		end
		
		if !params[:featured].nil?
			featured = @property.images.create({:url => @property.id.to_s + "-" + params[:featured][:filename].downcase.gsub(" ", "-") })
			@property.handle_upload(params[:featured], @property.id.to_s)
			@property.update({ :featured_img => featured.id })
			
			@property.generate_thumb(params[:featured], @property.id.to_s)
		end
		

		if !params[:layout_plan].nil?
			@property.handle_plan_upload(params[:layout_plan], @property.id.to_s, "layout")
			@property.update(:layout_plan => @property.id.to_s + "-" + params[:layout_plan][:filename].downcase.gsub(" ", "-"))
		end

		if !params[:master_plan].nil?
			@property.handle_plan_upload(params[:master_plan], @property.id.to_s, "master")
			@property.update(:master_plan => @property.id.to_s + "-" + params[:master_plan][:filename].downcase.gsub(" ", "-"))
		end
		
		redirect "/property/#{@property.id}/#{@property.slug}"
	else
		redirect '/properties'
	end
end

# Update action
put '/properties' do
	require_admin	
	@property = Property.get(params[:property][:id])
	update_params = params[:property]
	update_params.each_pair {|k,v| update_params[k] = nil if v.empty? }
	
	update_params[:layout_plan] = 
		@property.id.to_s + "-" + params[:layout_plan][:filename].downcase.gsub(" ", "-") unless params[:layout_plan].nil?
	update_params[:master_plan] = 
		@property.id.to_s + "-" + params[:master_plan][:filename].downcase.gsub(" ", "-") unless params[:master_plan].nil?
	
	gallDelete = params[:gallDels]
	
	gallUpload = params[:images]
	gallOrder = params[:gallOrder]
	layout_plan = params[:layout_plan]
	master_plan = params[:master_plan]
	
	

	unless gallOrder.nil?
		gallOrder.each_pair do |k, v|
			@image = Image.get(k)
			@image.update(:order_id => v.to_i)
		end
	end

	unless gallDelete.nil?
		gallDelete.each_pair do |key, value| 
			if !value.empty?
				Image.get(key).destroy
			end
		end
	end
	
	unless gallUpload.nil?
		params[:images].each do |image|
			new_order_id = Image.max(:order_id, :conditions => [ 'property_id = ?', @property.id ])
			new_order_id = new_order_id + 1 if new_order_id
			@property.images.create({ 
				:property_id => @property.id, 
				:url => @property.id.to_s + "-" + image[:filename].downcase.gsub(" ", "-"), 
				:order_id => new_order_id.to_i })
			@property.handle_upload(image, @property.id.to_s)	
		end
	end

	unless params[:featured].nil?
		featured = @property.images.create({:url => @property.id.to_s + "-" + params[:featured][:filename].downcase.gsub(" ", "-") })
		@property.handle_upload(params[:featured], @property.id.to_s)
		@property.update({ :featured_img => featured.id })
		@property.generate_thumb(params[:featured], @property.id.to_s)
	end

	
	@property.handle_plan_upload(layout_plan, @property.id.to_s, "layout") unless layout_plan.nil?

	@property.handle_plan_upload(master_plan, @property.id.to_s, "master") unless master_plan.nil?


	if @property.update(update_params)
		if request.referer.include? "admin"
			redirect request.referer
		else
			redirect "/property/#{@property.id}/#{@property.slug}"
		end
	else
		redirect "/admin"
	end
end


get '/admin' do	
	require_admin
	
	@regions = Region.all
	@states = State.all
	@categories = Category.all
	
	@classes = ['admin']
	@properties = Property.all
	@locations = Location.all(:order => [:name.asc])
	@types = Type.all
	
	@title = "Admin"

	erb :admin
end

get '/search' do
	@category = Category.new(:name => "All")
	
	@region = Region.get(params[:search][:region_id])
	@state = State.get(params[:search][:state])
	@category = Category.get(params[:search][:category]) if params[:search][:category] != "All"
	
	@locations = @region.locations(:order => [:name.asc])
	@properties = @locations.propertys(:state_id => @state.id, :is_active => true, :order => [:priority.desc])
	@locations = @properties.locations(:order => [:name.asc])
	
	if @category.name != "All"
		@properties = @properties.all(:category_id => @category.id) # selecting "Residential", "Commercial", etc
	end
	
	@location_ids = @locations.map(&:id) # For masonry filters
	@types = @properties.types
	
	@title = "#{@category.name} Properties for #{@state.name} in #{@region.name}"
	
	erb :search
end

delete '/property/:id' do
	require_admin
	@property = Property.get(params[:id])

	if @property.destroy
		redirect '/admin'
	else
		redirect '/'
	end	
end

# delete '/region/:id' do
# 	require_admin
# 	@region = Region.get(params[:id])
# 	if @region.destroy!
# 		redirect '/admin'
# 	else
# 		redirect '/'
# 	end
# end

post '/send-friend' do
	require 'pony'
	Pony.mail(
		:from => params[:friendmail][:frommail],
		:to => params[:friendmail][:tomail],
		:subject => params[:friendmail][:name] + " looked up a property for you",
		:headers => { 'Content-Type' => 'text/html' },
		:body => params[:friendmail][:mailbody] << "<br />Regards,<br />" << params[:friendmail][:name],
		:via => :smtp,
		:via_options => {
			:address              => 'smtp.sendgrid.net', 
	    	:port                 => '587', 
	    	:user_name            => 'hashcookies', 
	    	:password             => 'Nor1nderchqMudi', 
	    	:authentication       => :plain
		}
	)
	redirect request.referer
end

post '/send-inquiry' do
	require 'pony'
	@body = params[:inquiry][:body] + "<br />Inquiry Sent by: " + params[:inquiry][:name] + "<br />Phone: " + params[:inquiry][:phone] + "<br />Email: " + params[:inquiry][:eadd]
	Pony.mail(
		:from => params[:inquiry][:eadd],
		:to => "w@goapropertyco.com",
		:subject => "Inquiry for property",
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
	redirect request.referer
end

get '/sell-lease' do
	@classes = ['leasesell']
	@title = "Sell or Lease Your Property"
	erb :sell
end

post '/mail-sell-lease' do
	require 'pony'
	name = params[:leasesell][:name]
	state = params[:leasesell][:state]
	description = "<br />Property described as: " + params[:leasesell][:description] unless params[:leasesell][:description].nil?
	attachments = {}

	unless params[:images].nil?
		params[:images].each do |image|
			attachments[image[:filename].downcase.gsub(" ","-")] = File.read(image[:tempfile], :binmode => true)
		end
	end

	Pony.mail(
		:from => params[:leasesell][:email],
		:to => "w@goapropertyco.com",
		:subject => "Property for " + state,
		:html_body => name + " has a property for " + state + "<br />Property Type: " + params[:leasesell][:type] + "<br />Phone: " + params[:leasesell][:phone] + "<br />Email: " + params[:leasesell][:email] + description,
		:attachments => attachments,
		:via => :smtp,
		:via_options => {
			:address              => 'smtp.sendgrid.net', 
	    	:port                 => '587', 
	    	:user_name            => 'hashcookies', 
	    	:password             => 'Nor1nderchqMudi', 
	    	:authentication       => :plain
		}
	)
	redirect '/sell-lease'
end

configure do
		
		$blog_name = 'goapropco.tumblr.com'

		def client 
		# 	# tumblr initialization 
			return Tumblr::Client.new({
  				:consumer_key => 'pQzvSIuaXKfGAfHo86uBIKCnw1rapysNYOgGFj6FL5xTmXpV0H',
  				:consumer_secret => 'coTHJmyXvoqu4ypJ0JkYVa9aSpsT5HLm4lcQnRYa2IwKTzGRjw',
  				:oauth_token => 'BX3N9U51enQTLbZJSk5YUs0pZe8o0RzhoQbmZW1KEFcCMJLJio',
  				:oauth_token_secret => 'ZFEgnLrRrLJ2ZXx1moMdIn4dksFWBLKrHFmzWr78pXmoF3LkQ0'
			})
		end

		def posts 
			return client.posts($blog_name)['posts']
		end

		$knowledge = []
		$news = []
		$articles = []
		
		posts.each do |post|
				post['tags'].each do |tag|
					if (tag.downcase == 'news')
			
						$news << post

					elsif (tag.downcase == 'knowledge')
			
						$knowledge << post

					elsif (tag.downcase == 'articles' || tag.downcase == 'article')
			
						$articles << post
					end
				end
		end
		
end

before '/blog' do
	session[:posts] = posts
end

get '/blog' do
	@classes=['blog']
	@properties = Property.all(:limit => 5)
	@title ='Blog'	
	@posts = session[:posts]
	erb	:blog
end

get '/blog/:category/:id/:slug' do
		@classes = ['blog']
		@properties = Property.all(:limit => 5) 
		@parameter = params[:id].to_i
		@news = $news 
		@articles = $articles
		@knowledge = $knowledge  

		post = posts.find{|post| post['id'] == @parameter }
		@post_title = post['title']
		@post_body = post['body']
		@post_tags = (post['tags'].first).downcase

 		erb :blog_post
		
end
get '/blog/:category/:type' do 
	@classes = ['blog']
	@title = params[:type]	
	@properties = Property.all(:limit => 5)
	if params[:type] == 'news'
			@news = $news 
		elsif params[:type] == 'articles'
			@articles = $articles
		elsif params[:type] == 'knowledge'
			@knowledge = $knowledge  
	end
	
	erb :blog_categories

end

load 'actions/route_region.rb'
load 'actions/route_location.rb'
load 'actions/route_type.rb'



