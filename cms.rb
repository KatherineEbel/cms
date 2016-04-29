require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'pry'

before do 
  @files = Dir.foreach('data').reject { |filename| filename == '.' || filename == '..' }
end

configure do
  enable :sessions
  set :session_secret, 'secret'
end

get '/' do
  erb :index, layout: :layout
end

get "/:filename" do
  file_path = "data/" + params[:filename]
  if File.exist? file_path 
    headers["Content-Type"] = "text/plain"
    File.read file_path
  else
    session[:error] = "#{params[:filename]} not found"
    redirect '/'
  end
end
