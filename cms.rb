# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/content_for'
require 'redcarpet'
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  @directory = Dir.new(data_path)
  @markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  @user = session[:user]
end

helpers do
end

def data_path
  ENV['RACK_ENV'] == 'test' ? 'test/content' : 'content'
end

def path_for(filename)
  return "#{@directory.to_path}/#{filename}" if exists?(filename)

  session[:error] = "#{filename} does not exist."
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
  File.open(path, 'w') do |f|
    f.write text
  end
end

def error_for(file_name)
  if file_name.empty?
    'A name is required.'
  elsif !%w(.txt .md).include?(File.extname(file_name))
    'Invalid file type. Options include .txt and .md'
  end
end

get '/' do
  documents = @directory.children
  erb :index, locals: { documents: }
end

get '/new' do
  erb :new_document
end

get '/:filename' do
  render_file(path_for(params[:filename]))
end

get '/users/signin' do
  erb :signin
end

post '/users/signin' do
  username, password = params.values_at(:username, :password)
  if username == 'admin' && password == 'secret'
    session[:success] = 'Welcome!'
    session[:user] = username
    redirect '/'
  end
  session[:error] = 'Invalid Credentials'
  status 401
  erb :signin
end

post '/users/signout' do
  session.delete(:user)
  session[:success] = 'You have been signed out.'
  redirect '/'
end

get '/:filename/edit' do
  filename = params[:filename]
  path = path_for params[:filename]
  text = File.read(path)
  erb :edit_file, locals: { filename:, text: }
end

post '/new' do
  file_name = params[:file_name].strip
  error = error_for(file_name)
  if error
    session[:error] = error
    return erb :new_document
  end
  begin
    File.new(File.join(data_path, file_name), 'w')
    session[:success] = "#{file_name} was created."
    redirect '/'
  rescue Errno::ENOENT
    session[:error] = 'Server error: Unable to create file'
    erb :new_document
  end
end

put '/:filename/edit' do
  path = path_for(params[:filename])
  text = params[:text]
  write_file(path, text)
  session[:success] = "#{params[:filename]} has been updated."
  redirect '/'
end

delete '/:file_name' do
  path = path_for(params[:file_name])
  begin
    File.delete(path)
    session[:success] = "#{params[:file_name]} was deleted."
  rescue Errno::ENOENT
    session[:error] = 'Unable to delete file'
  end
  redirect '/'
end
