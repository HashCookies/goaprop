get '/location/new' do
	require_admin
	
	@regions = Region.all
	erb :new_location
end

post '/location/create' do
	location  = Location.create(params[:location])
	params[:region].each_value do |v|
		region = Region.get(v)
		location.regions << region
	end
	
	if location.save
		redirect '/admin'
	else
		redirect '/location/new'
	end
end

get '/location/:id' do
	@location = Location.get(params[:id])
	erb :location
end