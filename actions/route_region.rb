
get '/resource/new' do
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