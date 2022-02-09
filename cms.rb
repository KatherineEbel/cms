# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/content_for'
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  @directory = Dir.new('content')
end

helpers do
end

def path_for(filename)
  "#{@directory.to_path}/#{filename}"
end

def exists?(filename)
  @directory.children.include?(filename)
end

get '/' do
  documents = @directory.children
  erb :index, locals: { documents: }
end

get '/:filename' do
  if exists?(params[:filename])
    filename = path_for(params[:filename])
    return send_file filename, type: :txt
  end

  session[:error] = "#{params[:filename]} does not exist."
  redirect('/')
end
