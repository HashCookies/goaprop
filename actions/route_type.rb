get '/type/new' do
	erb :new_type
end

post '/type/create' do
	type  = Type.create(params[:type])
	
	if type.save
		redirect '/admin'
	else
		redirect '/type/new'
	end
end