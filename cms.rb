require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'pry'
get '/' do
  @files = Dir.foreach('data').reject { |filename| filename == '.' || filename == '..' }
  erb :index, layout: :layout
end

get "/:filename" do
  file_path = "data/" + params[:filename]
  headers["Content-Type"] = "text/plain"
  binding.pry
  @file = File.read file_path
end
