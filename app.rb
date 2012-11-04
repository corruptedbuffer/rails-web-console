require 'rubygems'
require 'sinatra/base'
# require 'eventmachine'
# require 'faye'
require './console'
require 'json'
require 'coffee-script'

class WebConsole < Sinatra::Base
  
  get '/' do
    erb :start
  end
  
  post '/start' do
    target = params['target']
    username = params['username']
    password = params['password']
    app_name = params['appname']

    console = Console.new
    console.connect target, username, password
    @guid, @prompt = console.console app_name

    erb :console
  end

  get '/start.json' do
    content_type 'text/json', :charset => 'utf-8'

    console = Console.new
    console.connect
    guid, prompt = console.console "rails-test-dh"

    { :status => 'ok', :guid => guid, :lines => [prompt] }.to_json
  end

  get '/sessions.json' do
    content_type 'text/json', :charset => 'utf-8'

    "{status: 'ok', sessions: ['#{Console.sessions.join("','")}']}"

  end

  get '/close/*.json' do
    content_type 'text/json', :charset => 'utf-8'
    guid = params[:splat].first

    Console.close_session guid

    "{status: 'ok'}"
  end

  get '/purge.json' do
    content_type 'text/json', :charset => 'utf-8'
    Console.purge_sessions

    "{status: 'ok'}"
  end

  post '/talk/*.json' do
    content_type 'text/json', :charset => 'utf-8'

    guid = params[:splat].first
    output = Console.talk guid, URI.unescape(params["msg"])

    { :status => 'ok', :guid => guid, :lines => output }.to_json
  end

  get '/coffee/*.js' do
    coffee params[:splat].first.to_sym
  end
  
  get '/scss/*.css' do
    scss params[:splat].first.to_sym, :style => :expanded
  end

  configure do
    set :public_folder, Proc.new { File.join(root, "public") }
    enable :sessions
  end

end

