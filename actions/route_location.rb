
get '/location/new' do
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
		redirect '/location/new'
	else
		redirect '/'
	end
end