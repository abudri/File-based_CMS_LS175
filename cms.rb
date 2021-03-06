# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'redcarpet' # Assignment: https://launchschool.com/lessons/ac566aae/assignments/98d2fce2
require 'yaml'
require 'bcrypt' # hashing passwords: https://launchschool.com/lessons/ac566aae/assignments/537af113

configure do
  enable :sessions # tells sinatra to activate it's session support
  set :sessions_secret, 'super secret' # setting the session secret, to the string 'secret'
end

def load_user_credentials
  credentials_path = if ENV['RACK_ENV'] == 'test'
                       File.expand_path('test/users.yml', __dir__) # users credentials file for testing purposes
                     else
                       File.expand_path('users.yml', __dir__) # use user crentials file, https://launchschool.com/lessons/ac566aae/assignments/c745b2fd
  end
  YAML.load_file(credentials_path)
end

def valid_credentials?(username, password)
  credentials = load_user_credentials # hashing passwords for security: https://launchschool.com/lessons/ac566aae/assignments/537af113

  if credentials.key?(username)
    bcrypt_password = BCrypt::Password.new(credentials[username])
    bcrypt_password == password
  else
    false
  end
end

def user_signed_in?
  session.key?(:username) # checking if user signed in, only accepts "admin" as of this point: https://launchschool.com/lessons/ac566aae/assignments/cf4382fe
end

def require_signed_in_user
  unless user_signed_in?
    session[:message] = 'You must be signed in to do that.'
    redirect '/'
  end
end

def data_path
  if ENV['RACK_ENV'] == 'test' # Assignment: https://launchschool.com/lessons/ac566aae/assignments/a23f0109
    File.expand_path('test/data', __dir__)
  else
    File.expand_path('data', __dir__)
  end
end

root = File.expand_path(__dir__)

# rendering markdown into HTML using the redcarpet gem
def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML) # from Assignment for rendering markdown files as HTML: https://launchschool.com/lessons/ac566aae/assignments/98d2fce2
  markdown.render(text)
end

def load_file_content(path)
  content = File.read(path)
  case File.extname(path)
  when '.txt'
    headers['Content-Type'] = 'text/plain'
    content
  when '.md'
    erb render_markdown(content) # `erb` added here: https://launchschool.com/lessons/ac566aae/assignments/84acfc0c
  end
end

# view an index or listing of the files in the CMS
get '/' do
  pattern = File.join(data_path, '*') # assignment https://launchschool.com/lessons/ac566aae/assignments/a23f0109
  @files = Dir.glob(pattern).map { |path| File.basename(path) }
  erb :index
end

# get view template form for creating a new file, we only enter the new file name here and taken back to the home index view. Note this has to be above the `get '/:filename' do` in order to not trigger error for non-existent file at this point
get '/new' do
  require_signed_in_user

  erb :new
end

# creating a new file by saving/posting it's name. Note this has to be above the `get '/:filename' do` in order to not trigger error for non-existent file at this point
post '/create' do
  require_signed_in_user

  filename = params[:filename].to_s # entered by user in url params
  if filename.empty?
    session[:message] = 'A name is required.'
    status 422
    erb :new
  else
    file_path = File.join(data_path, filename)

    File.write(file_path, '')
    session[:message] = "#{params[:filename]} has been created."

    redirect '/'
  end
end

# update/save edits to an existing file from the edit file form view template. Note this has to be above the `get '/:filename' do` in order to not trigger error for non-existent file at this point
post '/:filename' do
  require_signed_in_user
  file_path = File.join(data_path, params[:filename])

  File.write(file_path, params[:content])
  session[:message] = "#{params[:filename]} has been updated."
  redirect '/'
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
  require_signed_in_user

  file_path = File.join(data_path, params[:filename])

  @filename = params[:filename]
  @content = File.read(file_path)

  erb :edit
end

# delete a file
post '/:filename/delete' do
  require_signed_in_user

  file_path = File.join(data_path, params[:filename])

  File.delete(file_path)

  session[:message] = "#{params[:filename]} has been deleted"
  redirect '/'
end

# user sign in page view template
get '/users/signin' do
  erb :signin
end

# passing in signin credentials, accepted or rejected
post '/users/signin' do
  username = params[:username]

  if valid_credentials?(username, params[:password]) # refactored to use bcrypt: https://launchschool.com/lessons/ac566aae/assignments/537af113
    session[:username] = username
    session[:message] = 'Welcome!'
    redirect '/'
  else
    session[:message] = 'Invalid credentials'
    status 422
    erb :signin
  end
end

post '/users/signout' do
  session.delete(:username)
  session[:message] = 'You have been signed out'
  redirect '/'
end