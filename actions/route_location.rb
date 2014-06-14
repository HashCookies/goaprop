
get '/location/new' do
	@regions = Region.all
	erb :new_location
end

post '/location/create' do
	location  = Location.create(params[:location])
	region = Region.get(1)
	
	location.regions << region
	location.save

	
	if location.save
		redirect '/location/new'
	else
		redirect '/'
	end
end