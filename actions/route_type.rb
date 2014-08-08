get '/type/new' do
	@regions = Region.all
	@states = State.all
	@categories = Category.all
	@region = Region.first
	@category = Category.get 1
	@state = State.get 2
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

# get '/type/:id' do
# 	@type = Type.get(params[:id])
# 	@regions = Region.all
# 	@states = State.all
# 	@categories = Category.all
# 	@region = Region.first
# 	@category = Category.get 1
# 	@state = State.get 2
# 	erb :type
# end