
get '/location/new' do
	@regions = Region.all
	erb :new_location
end

post '/location/create' do
	location = Location.create(params[:location])
	region = Region.create
	LocationRegion.create(:location => location, :region => region)
	
	if location.save
		redirect '/location/new'
	else
		redirect '/'
	end
end