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

def admin?
  session[:username] == "admin"
end

def permission_denied
  status 422
  session[:message] = "You must be signed in to do that"
  redirect '/'
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

def valid_filename?
  filename.size > 0 && (filename.end_with?('.txt') || filename.end_with?('.md'))
end

def error_message(filename)
  case filename
  when filename.size == 0 then "A name is required"
  when filename.end_with?('.txt') || filename.end_with?('.md') 
    "Valid filenames include .txt or .md extensions."
  end
end

get '/' do
  pattern = File.join(data_path, "*")
  @files = Dir.glob(pattern).map do |path|
    File.basename(path)
  end
  erb :index, layout: :layout
end

get "/new" do
  admin? ? (erb :new) : permission_denied
end

post "/create" do
  filename = params[:filename].to_s
  permission_denied if !admin?
  if valid_filename?
    file_path = File.join(data_path, filename)
    File.write(file_path, '')
    session[:message] = "#{filename} has been created"
    redirect '/'
  else
    error_message filename
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
  if admin? 
    file_path = File.join(data_path, params[:filename])
    @filename = params[:filename]
    @content = File.read(file_path) 
    erb :edit
  else
    permission_denied
  end
end

post "/:filename" do
  if admin?
    file_path = File.join(data_path, params[:filename])
    File.write(file_path, params[:content])
    session[:message] = "#{params[:filename]} has been updated"
    redirect '/'
  else
    permission_denied
  end
end

post "/:filename/delete" do 
  if admin?
    file_path = File.join(data_path, params[:filename])
    File.delete(file_path)
    session[:message] = "#{params[:filename]} has been deleted"
    redirect '/'
  else
    permission_denied
  end
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
