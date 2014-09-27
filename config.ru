require './app'

set :protection, except: :session_hijacking

run Sinatra::Application
