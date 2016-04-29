require "sinatra"
require "sinatra/reloader"
require "pry"

before do
  @files = Dir.foreach("data").reject do |file|
    file == "." || file == ".."
  end 
end

helpers do
  def display(file)a
    file.split("\n\n")
  end
end

get "/" do
  
  erb :home, layout: :layout
end

get "/files/file" do

end
