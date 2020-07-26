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
end
