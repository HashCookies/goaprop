require './app'

set :environment, :demo
set :run, false

run Sinatra::Application
