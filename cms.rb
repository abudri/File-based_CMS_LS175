# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'

root = File.expand_path(__dir__)

get '/' do
  @files = Dir.glob(root + '/data/*').map { |path| File.basename(path) }
  erb :index
end

get '/:filename' do
  file_path = root + '/data/' + params[:filename]
  headers['Content-Type'] = 'text/plain'
  File.read(file_path) # this simply displays contexts of file, such as /data/history.txt.  We refefence the file in the applicaiton from root or home though, /history.txt
end
