require 'rubygems'
require 'sinatra'
require 'datamapper'

get '/' do
  erb 'Are you ready for an adventure?'
end