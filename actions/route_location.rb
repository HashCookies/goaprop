get '/location/new' do
	require_admin
	
	@regions = Region.all
	erb :new_location
end

get '/location/:id/edit' do
	require_admin
	@locations = Location.all(:id.not => params[:id])
	@location = Location.get(params[:id])
	@properties =  @location.propertys
	erb :edit_location
end

delete '/location/:id' do
	require_admin
	@properties = Property.all(:location_id => params[:id])
	@location = Location.get(params[:id])
	is_update = params[:action]
	update_success = false
	if is_update == "update"
		if @properties.update(:location_id => params[:property][:location_id])
			update_success = true
		else
			if @properties.destroy
				update_success = true
			end	
		end
	else
		update_success = true
	end
	if update_success
		if @location.destroy!
			redirect '/locations'
		else
			redirect '/'
		end
	else
		redirect '/locations'
	end
end

post '/location/create' do
	require_admin
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

get '/location/:id/:name' do
	@location = Location.get(params[:id])
	@properties =  @location.propertys
	erb :location
end

get '/locations' do
	require_admin
	@locations = Location.all(:order => [:name.asc])
	@properties = @locations.propertys
	erb :locations
end