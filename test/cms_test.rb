# frozen_string_literal: true

# test/cms_test.rb | Testing our Sinatra Application: https://launchschool.com/lessons/ac566aae/assignments/242be636
ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'

require_relative '../cms' # references cms.rb main program file

class CMSTest < Minitest::Test
  include Rack::Test::Methods # gain access to a bunch of useful testing helper methods

  def app
    Sinatra::Application # above Rack::Test::Methods methods expect a method called app to exist and return an instance of a Rack application when called
  end

  def test_index
    get '/'
    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'about.txt'
    assert_includes last_response.body, 'changes.txt'
    assert_includes last_response.body, 'history.txt'
  end

  def test_viewing_text_document
    get '/history.txt'

    assert_equal 200, last_response.status
    assert_equal 'text/plain', last_response['Content-Type']
    assert_includes last_response.body, '1993 - Yukihiro Matsumoto dreams up Ruby.'
  end

  def test_document_not_found
    get "/notafile.ext" # Attempt to access a nonexistent file

    assert_equal 302, last_response.status # Assert that the user was redirected

    get last_response["Location"] # Request the page that the user was redirected to

    assert_equal 200, last_response.status
    assert_includes last_response.body, "notafile.ext does not exist"

    get "/" # Reload the page
    refute_includes last_response.body, "notafile.ext does not exist" # Assert that our message has been removed
  end
end
