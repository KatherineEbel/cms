require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'redcarpet'
require 'pry'

root = File.expand_path('..', __FILE__)

def data_path
    if ENV['RACK_ENV'] == 'test'
      File.expand_path('../test/data', __FILE__)
    else
      File.expand_path('../data', __FILE__)
    end
  end


configure do
  enable :sessions
  set :session_secret, 'secret'
end

 def load_file(filepath)
  content = File.read filepath
  case File.extname(filepath)
  when '.txt'
    headers['Content-Type'] = 'text/plain'
    content
  when '.md'
    erb render_markdown(content)
  end
end

def render_markdown(text)
  markdown = Redcarpet::Markdown.new Redcarpet::Render::HTML
  markdown.render(text)
end

get '/' do
  pattern = File.join(data_path, "*")
  @files = Dir.glob(pattern).map do |path|
    File.basename(path)
  end
  erb :index, layout: :layout
end

get "/new" do
  erb :new
end

post "/create" do
  filename = params[:filename].to_s

  if filename.size == 0
    session[:message] = "A name is required"
    status 422
    erb :new
  elsif filename.end_with?('.txt') || filename.end_with?('.md')
    file_path = File.join(data_path, filename)
    File.write(file_path, '')
    session[:message] = "#{filename} has been created"
    redirect '/'
  else
    session[:message] = "Valid filenames include .txt and .md extensions."
    status 422
    erb :new 
  end
end

get "/:filename" do
  file_path = File.join(data_path, params[:filename])

  if File.exist?(file_path) 
    load_file file_path
  else
    session[:message] = "#{params[:filename]} not found"
    redirect '/'
  end
end
  
get "/:filename/edit" do
  file_path = File.join(data_path, params[:filename])
  @filename = params[:filename]
  @content = File.read(file_path) 
  erb :edit
end

post "/:filename" do
  file_path = File.join(data_path, params[:filename])
  File.write(file_path, params[:content])
  session[:message] = "#{params[:filename]} has been updated"
  redirect '/'
end

post "/:filename/delete" do 
  file_path = File.join(data_path, params[:filename])
  File.delete(file_path)
  session[:message] = "#{params[:filename]} has been deleted"
  redirect '/'
end

get "/users/signin" do
  erb :signin
end

post "/users/signin" do
  if params[:username] == "admin" && params[:password] == "secret"
    session[:username] = params[:username]
    session[:message] = "Welcome!"
    redirect '/'
  else
    session[:message] = "Invalid Credentials"
    status 422
    erb :signin 
  end
end

post "/users/signout" do 
  username = session[:username]
  session.delete(:username)
  session[:message] = "#{username} successfully signed out"
  redirect '/'
end
