# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/content_for'
require 'redcarpet'
require 'tilt/erubis'
require 'psych'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  @directory = Dir.new(data_path)
  @markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  @user = session[:user]
end

def data_path
  ENV['RACK_ENV'] == 'test' ? 'test/content' : 'content'
end

def user_data
  path = ENV['RACK_ENV'] == 'test' ? 'test/users.yaml' : 'config/users.yaml'
  Psych.load_file(path)
end

def authorized?
  !session[:user].nil?
end

def check_authorized
  return if authorized?
  session[:message] = 'You must be signed in to do that.'
  redirect '/', 401
end

def authenticate(username, password)
  return unless user_data.find { |u, p| u == username && p == password }

  session[:message] = 'Welcome!'
  session[:user] = username
  redirect '/'
end

def path_for(filename)
  return "#{@directory.to_path}/#{filename}" if exists?(filename)

  session[:message] = "#{filename} does not exist."
  redirect('/')
end

def exists?(filename)
  @directory.children.include?(filename)
end

def extension(filename)
  File.extname(filename)
end

def render_file(filename)
  case extension(filename)
  when '.txt' then send_file filename, type: :txt
  when '.md' then  erb @markdown.render(File.read(filename))
  else
    halt 500, 'Unhandled file extension'
  end
end

def write_file(path, text)
  File.open(path, 'w') { |f| f.write text }
end

def error_for(file_name)
  if file_name.empty?
    'A name is required.'
  elsif !%w(.txt .md).include?(File.extname(file_name))
    'Invalid file type. Options include .txt and .md'
  end
end

# get index
get '/' do
  documents = @directory.children
  erb :index, locals: { documents: }
end

# get new_document form
get '/new' do
  check_authorized
  erb :new_document
end

# view document
get '/:filename' do
  render_file(path_for(params[:filename]))
end

# get signin form
get '/users/signin' do
  erb :signin
end

# post signin
post '/users/signin' do
  username, password = params.values_at(:username, :password)
  authenticate(username, password)
  session[:message] = 'Invalid Credentials'
  status 401
  erb :signin
end

# post signout
post '/users/signout' do
  session.delete(:user)
  session[:message] = 'You have been signed out.'
  redirect '/'
end

get '/:filename/edit' do
  check_authorized
  filename = params[:filename]
  path = path_for params[:filename]
  text = File.read(path)
  erb :edit_file, locals: { filename:, text: }
end

post '/new' do
  check_authorized
  file_name = params[:file_name].strip
  error = error_for(file_name)
  if error
    session[:message] = error
    status 422
    return erb :new_document
  end
  begin
    File.new(File.join(data_path, file_name), 'w')
    session[:message] = "#{file_name} was created."
    redirect '/'
  rescue Errno::ENOENT
    session[:message] = 'Server error: Unable to create file'
    erb :new_document
  end
end

put '/:filename/edit' do
  check_authorized
  path = path_for(params[:filename])
  text = params[:text]
  write_file(path, text)
  session[:message] = "#{params[:filename]} has been updated."
  redirect '/'
end

delete '/:file_name' do
  check_authorized
  path = path_for(params[:file_name])
  begin
    File.delete(path)
    session[:message] = "#{params[:file_name]} was deleted."
  rescue Errno::ENOENT
    session[:message] = 'Unable to delete file'
  end
  redirect '/'
end
