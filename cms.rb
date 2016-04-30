require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'redcarpet'
require 'pry'

root = File.expand_path('..', __FILE__)

before do 
  @files = Dir.foreach('data').reject { |filename| filename == '.' || filename == '..' }
end

configure do
  enable :sessions
  set :session_secret, 'secret'
end

helpers do
  def load_file(filepath)
    content = File.read filepath
    case File.extname(filepath)
    when '.txt'
      headers['Content-Type'] = 'text/plain'
      content
    when '.md'
      render_markdown content
    end
  end

  def render_markdown(text)
    markdown = Redcarpet::Markdown.new Redcarpet::Render::HTML
    markdown.render(text)
  end
end

get '/' do
  erb :index, layout: :layout
end

get "/:filename" do
  file_path = "data/" + params[:filename]
  if File.exist?(file_path) 
    load_file file_path
  else
    session[:message] = "#{params[:filename]} not found"
    redirect '/'
  end
end
  
get "/:filename/edit" do
  file_path = "data/" + params[:filename]
  @filename = params[:filename]
  @content = File.read(file_path)
  erb :edit, layout: :layout
end

post "/:filename" do
  file_path = root + "/data/" + params[:filename]
  File.write(file_path, params[:content])
  session[:message] = "#{params[:filename]} has been updated"
  redirect '/'
end




