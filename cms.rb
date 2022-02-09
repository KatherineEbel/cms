# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/content_for'
require 'redcarpet'
require 'tilt/erubis'

DIR_NAME = ENV['RACK_ENV'] == 'test' ? 'test/content' : 'content'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  @directory = Dir.new(DIR_NAME)
  @markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
end

helpers do
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
  when '.md' then  @markdown.render(File.read(filename))
  else
    halt 500, 'Unhandled file extension'
  end
end

def write_file(path, text)
  File.open(path, 'w') do |f|
    f.puts text
  end
end

get '/' do
  documents = @directory.children
  erb :index, locals: { documents: }
end

get '/:filename' do
  render_file(path_for(params[:filename]))
end

get '/:filename/edit' do
  filename = params[:filename]
  path = path_for params[:filename]
  text = File.read(path)
  erb :edit_file, locals: { filename:, text: }
end

put '/:filename/edit' do
  path = path_for(params[:filename])
  text = params[:text]
  write_file(path, text)
  session[:success] = "#{params[:filename]} has been updated."
  redirect '/'
end
