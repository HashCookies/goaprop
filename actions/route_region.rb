get '/region/new' do
	@locations = Location.all
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

get '/region/:id' do
	@region = Region.get(params[:id])
	erb :region
end