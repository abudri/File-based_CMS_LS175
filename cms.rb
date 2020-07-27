require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require "redcarpet" # Assignment: https://launchschool.com/lessons/ac566aae/assignments/98d2fce2


configure do
  enable :sessions # tells sinatra to activate it's session support
  set :sessions_secret, 'super secret' # setting the session secret, to the string 'secret'
end

# configure do
#   set :erb, escape_html: true # Lesson 6, Sanitizing HTML: https://launchschool.com/lessons/31df6daa/assignments/d98e4174
# end

def data_path
  if ENV["RACK_ENV"] == "test"  # Assignment: https://launchschool.com/lessons/ac566aae/assignments/a23f0109
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

root = File.expand_path(__dir__)

# rendering markdown into HTML using the redcarpet gem
def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)  # from Assignment for rendering markdown files as HTML: https://launchschool.com/lessons/ac566aae/assignments/98d2fce2
  markdown.render(text)
end

def load_file_content(path)
  content = File.read(path)
  case File.extname(path)
  when ".txt"
    headers["Content-Type"] = "text/plain"
    content
  when ".md"
    erb render_markdown(content) # `erb` added here: https://launchschool.com/lessons/ac566aae/assignments/84acfc0c
  end
end

# view an index or listing of the files in the CMS
get '/' do
  pattern = File.join(data_path, "*") # assignment https://launchschool.com/lessons/ac566aae/assignments/a23f0109
  @files = Dir.glob(pattern).map { |path| File.basename(path) }
  erb :index
end

# get view template form for creating a new file, we only enter the new file name here and taken back to the home index view. Note this has to be above the `get '/:filename' do` in order to not trigger error for non-existent file at this point
get '/new' do
  erb :new
end

# creating a new file by saving/posting it's name. Note this has to be above the `get '/:filename' do` in order to not trigger error for non-existent file at this point
post '/create' do
  filename = params[:filename].to_s # entered by user in url params
  if filename.size == 0 
    session[:message] = "A name is required."
    status 422
    erb :new
  else
    file_path = File.join(data_path, filename)

    File.write(file_path, "")
    session[:message] = "#{params[:filename]} has been created."

    redirect "/"
  end
end

# update/save edits to an existing file from the edit file form view template. Note this has to be above the `get '/:filename' do` in order to not trigger error for non-existent file at this point
post '/:filename' do
  file_path = File.join(data_path, params[:filename])

  File.write(file_path, params[:content])
  session[:message] = "#{params[:filename]} has been updated."
  redirect "/"
end


# view a file
get '/:filename' do
  file_path = File.join(data_path, params[:filename])

  if File.exist?(file_path)
    load_file_content(file_path) # this simply displays contexts of file, such as /data/history.txt.  We refefence the file in the applicaiton from root or home though, /history.txt
  else
    session[:message] = "#{params[:filename]} does not exist."
    redirect '/'
  end
end

# get the view template for editing an existing file
get '/:filename/edit' do
  file_path = File.join(data_path, params[:filename])

  @filename = params[:filename]
  @content = File.read(file_path)

  erb :edit
end