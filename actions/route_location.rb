get '/location/new' do
	@regions = Region.all
	@states = State.all
	@categories = Category.all
	@region = Region.first
	@category = Category.get 1
	@state = State.get 2
	erb :new_location
end

post '/location/create' do
	location  = Location.create(params[:location])
	params[:region].each_value do |v|
		region = Region.get(v)
		location.regions << region
	end
	
	if location.save
		redirect '/'
	else
		redirect '/location/new'
	end
end

get '/location/:id' do
	@location = Location.get(params[:id])
	erb :location
end