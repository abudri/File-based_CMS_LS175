# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'

configure do
  enable :sessions # tells sinatra to activate it's session support
  set :sessions_secret, 'super secret' # setting the session secret, to the string 'secret'
end

configure do
  set :erb, escape_html: true # Lesson 6, Sanitizing HTML: https://launchschool.com/lessons/31df6daa/assignments/d98e4174
end

root = File.expand_path(__dir__)

get '/' do
  @files = Dir.glob(root + '/data/*').map { |path| File.basename(path) }
  erb :index
end

get '/:filename' do
  file_path = root + '/data/' + params[:filename]

  if File.file?(file_path)
    headers['Content-Type'] = 'text/plain'
    File.read(file_path) # this simply displays contexts of file, such as /data/history.txt.  We refefence the file in the applicaiton from root or home though, /history.txt
  else
    session[:message] = "#{params[:filename]} does not exist."
    redirect '/'
  end
end
