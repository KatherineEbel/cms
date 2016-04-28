require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubis"

get "/" do
  @message = "Getting Started"
end
