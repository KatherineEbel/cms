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
  erb :edit, layout: :layout
end

post "/:filename" do
  file_path = File.join(data_path, params[:filename])
  File.write(file_path, params[:content])
  session[:message] = "#{params[:filename]} has been updated"
  redirect '/'
end

post "/:filename/new" do

end


