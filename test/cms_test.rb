# frozen_string_literal: true

# test/cms_test.rb | Testing our Sinatra Application: https://launchschool.com/lessons/ac566aae/assignments/242be636
ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require 'fileutils' # https://launchschool.com/lessons/ac566aae/assignments/a23f0109

require_relative '../cms' # references cms.rb main program file

class CMSTest < Minitest::Test
  include Rack::Test::Methods # gain access to a bunch of useful testing helper methods

  def app
    Sinatra::Application # above Rack::Test::Methods methods expect a method called app to exist and return an instance of a Rack application when called
  end

  def setup
    FileUtils.mkdir_p(data_path) # https://launchschool.com/lessons/ac566aae/assignments/a23f0109
  end

  def teardown
    FileUtils.rm_rf(data_path) # https://launchschool.com/lessons/ac566aae/assignments/a23f0109
  end

  def create_document(name, content = '')
    File.open(File.join(data_path, name), 'w') do |file| # Assignment https://launchschool.com/lessons/ac566aae/assignments/a23f0109 /  a simple way to create documents during testing. Creates empty files by default, but an optional second parameter allows the contents of the file to be passed in
      file.write(content)
    end
  end

  def session
    last_request.env['rack.session'] # Assignment https://launchschool.com/lessons/ac566aae/assignments/52d6d56d
  end

  def admin_session
    { 'rack.session' => { username: 'admin' } } # creates a signed in user for us, in effect: https://launchschool.com/lessons/ac566aae/assignments/cf4382fe
  end

  # testing application function from here down, above is setup and helping methods

  def test_index
    create_document 'about.md' # setup necessary data
    create_document 'changes.txt' # setup necessary data

    get '/' # Execute the code being tested

    assert_equal 200, last_response.status # Assert results of execution, this line and down
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'about.md'
    assert_includes last_response.body, 'changes.txt'
  end

  def test_viewing_text_document
    create_document 'history.txt', '1993 - Yukihiro Matsumoto dreams up Ruby.' # not showing parenthesis here, setting up necessary data

    get '/history.txt' # Execute the code being tested

    assert_equal 200, last_response.status # Assert results of execution, this line and down
    assert_equal 'text/plain', last_response['Content-Type']
    assert_includes last_response.body, '1993 - Yukihiro Matsumoto dreams up Ruby.'
  end

  def test_document_not_found
    get '/notafile.ext' # Attempt to access a nonexistent file

    assert_equal 302, last_response.status # Assert that the user was redirected
    assert_equal 'notafile.ext does not exist.', session[:message] # refactored using sessions, assignment https://launchschool.com/lessons/ac566aae/assignments/52d6d56d
  end

  def test_viewing_markdown_document
    create_document 'about.md', '# Ruby is...' # second argument is markdown format, which should be converted to HTML by redcarpet gem
    get '/about.md'

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, '<h1>Ruby is...</h1>'
  end

  def test_editing_document
    create_document 'changes.txt' # setup test data

    get '/changes.txt/edit', {}, admin_session # user signed in. # getting the form for editing a document / execute code being testedf

    assert_equal 200, last_response.status
    assert_includes last_response.body, '<textarea'
    assert_includes last_response.body, '<button type="submit"'
  end

  def test_editing_document_signed_out
    create_document 'changes.txt' # setup test data. signed in testing: https://launchschool.com/lessons/ac566aae/assignments/cf4382fe

    get '/changes.txt/edit' # user signed in. # getting the form for editing a document / execute code being testedf

    assert_equal 302, last_response.status
    assert_equal 'You must be signed in to do that.', session[:message]
end

  def test_updating_document
    post '/changes.txt', { content: 'new content' }, admin_session

    assert_equal 302, last_response.status
    assert_equal 'changes.txt has been updated.', session[:message] # refactored using sessions, assignment https://launchschool.com/lessons/ac566aae/assignments/52d6d56d

    get '/changes.txt'
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'new content'
  end

  def test_updating_document_signed_out
    post '/changes.txt', content: 'new content'

    assert_equal 302, last_response.status
    assert_equal 'You must be signed in to do that.', session[:message]
  end

  def test_view_new_document_form
    get '/new', {}, admin_session # assignment: https://launchschool.com/lessons/ac566aae/assignments/e1e7cf2a. refactored with sign in: https://launchschool.com/lessons/ac566aae/assignments/cf4382fe

    assert_equal 200, last_response.status
    assert_includes last_response.body, '<input'
    assert_includes last_response.body, '<button type="submit"'
  end

  def test_view_new_document_form_signed_out
    get '/new' # assignment: https://launchschool.com/lessons/ac566aae/assignments/e1e7cf2a. refactored with sign in: https://launchschool.com/lessons/ac566aae/assignments/cf4382fe

    assert_equal 302, last_response.status
    assert_equal 'You must be signed in to do that.', session[:message]
  end

  def test_create_new_document
    post '/create', { filename: 'test.txt' }, admin_session # assignment: https://launchschool.com/lessons/ac566aae/assignments/e1e7cf2a. refactored: https://launchschool.com/lessons/ac566aae/assignments/cf4382fe
    assert_equal 302, last_response.status
    assert_equal 'test.txt has been created.', session[:message]

    get '/'
    assert_includes last_response.body, 'test.txt'
  end

  def test_create_new_document_signed_out
    post '/create', filename: 'test.txt' # assignment: https://launchschool.com/lessons/ac566aae/assignments/e1e7cf2a. refactored: https://launchschool.com/lessons/ac566aae/assignments/cf4382fe

    assert_equal 302, last_response.status
    assert_equal 'You must be signed in to do that.', session[:message]
  end

  def test_create_new_document_without_filename
    post '/create', { filename: '' }, admin_session # assignment: https://launchschool.com/lessons/ac566aae/assignments/e1e7cf2a
    assert_equal 422, last_response.status
    assert_includes last_response.body, 'A name is required'
  end

  def test_deleting_document
    create_document('test.txt')

    post '/test.txt/delete', {}, admin_session
    assert_equal 302, last_response.status
    assert_equal 'test.txt has been deleted', session[:message]

    get '/'
    refute_includes last_response.body, 'href="/test.txt"'
  end

  def test_deleting_document_signed_out
    create_document('test.txt')

    post '/test.txt/delete'
    assert_equal 302, last_response.status
    assert_equal 'You must be signed in to do that.', session[:message]
  end

  def test_signin_form
    get '/users/signin'

    assert_equal 200, last_response.status
    assert_includes last_response.body, '<input'
    assert_includes last_response.body, '<button type="submit"'
  end

  def test_signin
    
    post '/users/signin', username: 'admin', password: 'secret'
    assert_equal 302, last_response.status
    assert_equal 'Welcome!', session[:message]
    assert_equal 'admin', session[:username]

    get last_response['Location']
    assert_includes last_response.body, 'Signed in as admin'
  end

  def test_signin_with_bad_credentials
    post '/users/signin', username: 'guest', password: 'shhhh'
    assert_equal 422, last_response.status
    assert_nil session[:username]
    assert_includes last_response.body, 'Invalid credentials'
  end

  def test_signout
    get '/', {}, 'rack.session' => { username: 'admin' }
    assert_includes last_response.body, 'Signed in as admin'

    post '/users/signout'
    assert_equal 'You have been signed out', session[:message] # refactored using sessions, https://launchschool.com/lessons/ac566aae/assignments/52d6d56d

    get last_response['Location']
    assert_nil session[:username]
    assert_includes last_response.body, 'Sign In'
  end
end
