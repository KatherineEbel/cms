# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require_relative '../cms'
require 'fileutils'

class CMSTest < Minitest::Test
  include Rack::Test::Methods

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

  def test_index
    get '/'
    assert last_response.ok?
    assert_equal('text/html;charset=utf-8', last_response['Content-Type'])
    %w[about.md changes.txt].each do |f|
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
    get last_response['Location']
    assert last_response.ok?
    assert_includes last_response.body, expected_text

    get '/'
    refute_includes last_response.body, expected_text
  end

  def test_markdown_file
    get '/about.md'
    assert last_response.ok?
    assert_equal last_response['Content-Type'], 'text/html;charset=utf-8'
    assert_includes last_response.body, '<h1>Ruby is...</h1>'
  end

  def test_get_edit_form
    get '/changes.txt/edit'
    assert last_response.ok?
  end

  def test_edit_form_controls
    get '/changes.txt/edit'
    assert_includes last_response.body, '<textarea name="text"'
    assert_includes last_response.body, '<button type="submit"'
  end

  def test_text_area_contains_file
    get '/changes.txt/edit'
    assert_includes last_response.body, "I'm baby shabby chic"
  end

  def test_put_file
    put '/changes.txt/edit', text: 'Foo'
    expected_text = 'changes.txt has been updated.'
    assert_equal(302, last_response.status)
    get last_response['Location']
    assert last_response.ok?
    assert_includes last_response.body, expected_text
  end

  def test_new_document_link
    get '/'
    assert_includes last_response.body, 'New Document'
  end

  def test_get_new
    get '/new'
    assert last_response.ok?
    assert_includes last_response.body, '<input type="text"'
    assert_includes last_response.body, '<button type="submit"'
    assert_includes last_response.body, 'Add a new document'
    assert_includes last_response.body, 'Create'
  end

  def test_post_new
    post '/new', file_name: 'story.md'

    expected_text = 'story.md was created.'
    get last_response['Location']
    assert last_response.ok?
    assert_includes last_response.body, expected_text
    assert_includes last_response.body, 'story.md'

    get '/'
    refute_includes last_response.body, expected_text
  end

  def test_post_new_no_name
    post '/new', file_name: '     '
    assert_includes last_response.body, 'A name is required.'
  end

  def test_post_invalid_ext
    post '/new', file_name: 'story.jpg'
    assert_includes last_response.body, 'Invalid file type. Options include .txt and .md'
  end

  def test_delete_button_exists
    get '/'

    count = last_response.body.scan(/<button/).size
    assert_equal(2, count)
  end

  def test_delete_file
    delete '/changes.txt'

    expected_text = 'changes.txt was deleted.'
    get last_response['Location']
    assert last_response.ok?
    assert_includes last_response.body, expected_text

    count = last_response.body.scan(/<button/).size
    assert_equal(1, count)
    get '/'
    refute_includes last_response.body, expected_text
  end
end
