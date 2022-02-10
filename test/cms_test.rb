# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require_relative '../cms'
require 'fileutils'

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def admin_session
    { 'rack.session' => { user: 'admin' } }
  end

  def session
    last_request.env['rack.session']
  end

  def create_document(name, content = '')
    File.open(File.join(data_path, name), 'w') do |file|
      file.write(content)
    end
  end

  def setup
    FileUtils.mkdir_p(data_path)
    create_document('changes.txt', "I'm baby shabby chic")
    create_document('about.md', '<h1>Ruby is...</h1>')
  end

  def teardown
    FileUtils.rm_rf(data_path)
  end

  def app
    Sinatra::Application
  end

  def test_index_lists_files
    get '/'
    assert last_response.ok?
    assert_equal('text/html;charset=utf-8', last_response['Content-Type'])
    %w(about.md changes.txt).each do |f|
      assert last_response.body.include?(f)
    end
  end

  def test_get_file
    get '/changes.txt'
    assert last_response.ok?
    assert_equal('text/plain;charset=utf-8', last_response['Content-Type'])
    assert_includes last_response.body, "I'm baby shabby chic"
  end

  def test_nonexistant_file
    get '/foo.txt'
    expected_text = 'foo.txt does not exist.'
    assert_equal(302, last_response.status)
    assert_equal expected_text, session[:message]
  end

  def test_flash_removed
    get '/foo.txt'
    assert_equal 'foo.txt does not exist.', session[:message]
    get '/'
    assert_nil session[:message]
  end

  def test_markdown_file
    get '/about.md'
    assert last_response.ok?
    assert_equal last_response['Content-Type'], 'text/html;charset=utf-8'
    assert_includes last_response.body, '<h1>Ruby is...</h1>'
  end

  def test_get_edit_form
    get '/changes.txt/edit', {}, admin_session
    assert last_response.ok?
    assert_includes last_response.body, '<textarea name="text"'
    assert_includes last_response.body, '<button type="submit"'
  end

  def test_text_area_contains_file
    get '/changes.txt/edit', {}, admin_session
    assert_includes last_response.body, "I'm baby shabby chic"
  end

  def test_put_file
    put '/changes.txt/edit', { text: 'Foo' }, admin_session
    assert_equal(302, last_response.status)
    assert_equal 'changes.txt has been updated.', session[:message]
  end

  def test_new_document_link
    get '/'
    assert_includes last_response.body, 'New Document'
  end

  def test_get_new
    get '/new', {}, admin_session
    assert last_response.ok?
    assert_includes last_response.body, '<input type="text"'
    assert_includes last_response.body, '<button type="submit"'
    assert_includes last_response.body, 'Add a new document'
    assert_includes last_response.body, 'Create'
  end

  def test_post_new
    post '/new', { file_name: 'story.md' }, admin_session

    assert_equal 302, last_response.status
    assert_equal 'story.md was created.', session[:message]
    get '/'
    assert_includes last_response.body, 'story.md'
  end

  def test_post_new_no_name
    post '/new', { file_name: '' }, admin_session
    assert_includes last_response.body, 'A name is required.'
  end

  def test_post_invalid_ext
    post '/new', { file_name: 'story.jpg' }, admin_session
    assert_includes last_response.body,
                    'Invalid file type. Options include .txt and .md'
  end

  def test_delete_buttons_exist
    get '/'

    count = last_response.body.scan(/Delete/).size
    assert_equal(2, count)
  end

  def test_delete_file
    delete '/changes.txt', {}, admin_session

    assert_equal 302, last_response.status
    assert_equal 'changes.txt was deleted.', session[:message]

    get '/'
    count = last_response.body.scan(/Delete/).size
    assert_equal(1, count)
    refute_includes last_response.body, 'href="/changes.txt"'
  end

  def test_index_logged_out
    get '/'
    assert_includes last_response.body, 'Sign In'
  end

  def test_get_signin
    get '/users/signin'
    assert_includes last_response.body, '<button type="submit"'
    assert_equal 2, last_response.body.scan(/<input/).size
    assert_includes last_response.body, '<button type="submit"'
  end

  def test_signin_valid
    post '/users/signin', username: 'admin', password: 'supersecret'
    assert_equal(302, last_response.status)
    assert_equal 'Welcome!', session[:message]
    get last_response['Location']
    assert_includes last_response.body, 'Signed in as admin.'
    assert_includes last_response.body, 'Sign Out'
  end

  def test_signin_invalid
    post '/users/signin', username: 'johnny', password: 'foo'
    expected_text = 'Invalid Credentials'
    assert_equal 401, last_response.status
    assert_includes last_response.body, expected_text
    refute_includes last_response.body, 'Signed in as admin.'
    refute_includes last_response.body, 'Sign Out'
  end

  def test_signout
    get '/', {}, { 'rack.session' => { user: 'admin' } }
    assert_includes last_response.body, 'Signed in'
    post '/users/signout'
    assert_equal 'You have been signed out.', session[:message]

    get last_response['Location']
    assert_nil session[:user]
    assert_includes last_response.body, 'Sign In'
  end

  def test_get_edit_no_user
    get '/changes.txt/edit'
    assert_equal 401, last_response.status
    assert_equal 'You must be signed in to do that.', session[:message]
  end

  def test_put_edit_no_user
    put '/changes.txt/edit', text: 'Foo'
    assert_equal 401, last_response.status
    assert_equal 'You must be signed in to do that.', session[:message]
  end

  def test_get_new_no_user
    get '/new'
    assert_equal 401, last_response.status
    assert_equal 'You must be signed in to do that.', session[:message]
  end

  def test_post_new_no_user
    post '/new', file_name: 'story.md'
    assert_equal 401, last_response.status
    assert_equal 'You must be signed in to do that.', session[:message]
  end

  def test_delete_no_user
    delete '/changes.txt'
    assert_equal 401, last_response.status
    assert_equal 'You must be signed in to do that.', session[:message]
  end
end
