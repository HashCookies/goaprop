get '/region/new' do
	@locations = Location.all
	erb :new_region
end

post '/region/create' do
	@region = Region.new(params[:region])
	if @region.save
		redirect '/admin'
	else
		redirect '/region/new'
	end
end

get '/region/:id' do
	@thisregion = Region.get(params[:id])
	erb :region
end