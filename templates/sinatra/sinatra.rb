##################### Setup

require 'rubygems'
require 'sinatra'
require 'haml'
require 'sass'
require 'dm-core'
DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/log/rivup.db")
set :public, 'public'
set :sass, {:style => :compressed }

##################### DataMapper

class ClickTracker
  include DataMapper::Resource
  property :id, Serial
  property :virtual_freed_downloads, Integer, :default => 0
end

# Create/Upgrade/Migrate database automatically
DataMapper.auto_upgrade!

##################### Sass

get '/stylesheets/global.css' do
  headers 'Content-Type' => 'text/css; charset=utf-8'
  sass :"sass/global"
end

get '/stylesheets/ie.css' do
  headers 'Content-Type' => 'text/css; charset=utf-8'
  sass :"sass/ie"
end

get '/stylesheets/mobile.css' do
  headers 'Content-Type' => 'text/css; charset=utf-8'
  sass :"sass/mobile"
end

get '/stylesheets/print.css' do
  headers 'Content-Type' => 'text/css; charset=utf-8'
  sass :"sass/print"
end

get '/stylesheets/screen.css' do
  headers 'Content-Type' => 'text/css; charset=utf-8'
  sass :"sass/screen"
end

##################### Main Routes

before  do
  headers 'Content-Type' => 'text/html; charset=utf-8'
end

get '/' do
  @title = "Rivup Software. Random creations in code."
  haml :index
end

post '/download' do
  @clicks = ClickTracker.new
  @clicks.save
  send_file "#{Dir.pwd}/public/virtual_freed_0.1.3.zip", :filename => "Virtual Freed 0.1.3.zip"
end