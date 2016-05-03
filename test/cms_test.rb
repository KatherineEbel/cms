ENV["RACK_ENV"] = "test"

require 'minitest/autorun'
require 'rack/test'
require 'fileutils'
require 'yaml'

require_relative '../cms'

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def setup
    FileUtils.mkdir_p(data_path)
  end

  def teardown
    FileUtils.rm_rf(data_path)
  end

  def create_document(name, content='')
    File.open(File.join(data_path, name), 'w') do |file|
      file.write(content)
    end
  end

  def app
    Sinatra::Application
  end
  
  def session
    last_request.env['rack.session']
  end

  def admin_session
    { "rack.session" => { username: "bill" } }
  end

  def test_index
    create_document "about.md"
    create_document "changes.txt"
    get '/'
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, 'about.md'
    assert_includes last_response.body, 'changes.txt'
  end

  def test_viewing_text_document
    create_document 'history.txt', '1993 - Yukihiro Matsumoto dreams up Ruby.'
    get '/history.txt'
    assert_equal 200, last_response.status 
    assert_equal "text/plain", last_response["Content-Type"]
    assert_includes last_response.body, "1993 - Yukihiro Matsumoto dreams up Ruby."
  end

  def test_file_not_found
    get '/nothere.txt'
    assert_equal 302, last_response.status
    assert_includes "nothere.txt not found", session[:message]
  end

  def test_renders_markdown
    create_document 'about.md', '# Ruby is...'
    get '/about.md'
    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response["Content-Type"]
    assert_includes last_response.body, '<h1>Ruby is...</h1>'
  end

  def test_signed_out_editing_file
    create_document "changes.txt"
    get "/changes.txt/edit"
    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that", session[:message]
  end

  def test_editing_file
    create_document 'changes.txt', '1993 - Yukihiro Matsumoto dreams up Ruby.'
    get "/changes.txt/edit", {}, admin_session

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<textarea"
    assert_includes last_response.body, %q(<button type="submit")
  end

  def test_signed_out_update_file
    post "/changes.txt", content: "new content"
    assert_equal 302, last_response.status 
    assert_equal "You must be signed in to do that", session[:message]
  end

  def test_file_updated
    create_document 'changes.txt'
    post "/changes.txt", { content: "new content" }, admin_session

    assert_equal 302, last_response.status
    assert_equal 'changes.txt has been updated', session[:message]

    get "/changes.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "new content"
  end

  def test_signed_out_new_file
    get '/new' 
    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that", session[:message]
  end

  def test_new_file_form_loads
    get "/new", {}, admin_session
    assert_equal 200, last_response.status
    assert_includes last_response.body, "Add a new document:"
    assert_includes last_response.body, %q(<button type="submit")
  end

  def test_signed_out_create_new_file
    post "/create", filename: "test.txt"
    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that", session[:message]
  end

  def test_create_new_file
    post "/create", { filename: "test.txt" }, admin_session
    assert_equal 302, last_response.status 
    assert_equal "test.txt has been created", session[:message]

    get "/"
    assert_includes last_response.body, "test.txt"
  end

  def test_new_document_without_name
    post "/create", { filename: "" }, admin_session
    assert_equal 422, last_response.status
    assert_includes last_response.body, "A name is required"
  end

  def test_signed_out_deleting_document
    create_document "test.txt", ""
    post "/test.txt/delete"
    assert_equal 302, last_response.status
    assert_includes "You must be signed in to do that", session[:message]
  end

  def test_deleting_document
    create_document "test.txt", ""

    post "/test.txt/delete", {}, admin_session 
    assert_equal 302, last_response.status 
    
    assert_includes "test.txt has been deleted", session[:message]

    get '/'
    refute_includes last_response.body, %q(href="/test.txt")
  end

  def test_sign_in_page
    get '/users/signin'

    assert_equal 200, last_response.status
    assert_includes last_response.body, '<input'
    assert_includes last_response.body, %q(<button type="submit")  
  end

  def test_signin
    post "/users/signin", { username: "bill", password: "billspassword" }
    assert_equal 302, last_response.status 
    assert_equal "Welcome!", session[:message]
    assert_equal "bill", session[:username]

    get last_response['Location']
    assert_includes last_response.body, "Signed in as bill"
  end
  
  def test_signin_invalid_credentials
    post "/users/signin", { username: "baduser", password: "wrongsecret" }
    assert_equal 422, last_response.status
    assert_equal nil, session[:username]
    assert_includes last_response.body, "Invalid Credentials"
  end
  
  def test_signout
    get "/", {}, {'rack.session' => { username: 'bill' } }
    assert_includes last_response.body, "Signed in as bill"

    post "/users/signout"
    follow_redirect!
    assert_equal nil, session[:username]
    assert_includes last_response.body, "successfully signed out"
    assert_includes last_response.body, "Sign In"
  end
end
