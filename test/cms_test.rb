# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require_relative '../cms'

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def write_test_file
    path = Dir.new('test/content')
    File.new("#{path.to_path}/test.txt", 'w')
  end

  def setup
    write_test_file
  end

  def app
    Sinatra::Application
  end

  def test_index
    get '/'
    assert last_response.ok?
    assert_equal('text/html;charset=utf-8', last_response['Content-Type'])
    %w[about.txt changes.txt history.txt].each do |f|
      assert last_response.body.include?(f)
    end
  end

  def test_get_file
    get '/about.txt'
    assert last_response.ok?
    assert_equal('text/plain;charset=utf-8', last_response['Content-Type'])
    assert_includes last_response.body, "I'm baby shabby chic"
  end

  def test_get_another_file
    get '/changes.txt'
    assert last_response.ok?
    assert_equal('text/plain;charset=utf-8', last_response['Content-Type'])
    assert last_response.body.include?('Photo booth fixie iPhone')
  end

  def test_get_final_file
    get '/history.txt'
    assert last_response.ok?
    assert_equal('text/plain;charset=utf-8', last_response['Content-Type'])
    assert last_response.body.include?('Organic tattooed chia, mixtape shabby chic')
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
    get '/about.txt/edit'
    assert last_response.ok?
  end

  def test_edit_form_controls
    get '/about.txt/edit'
    assert_includes last_response.body, '<textarea'
    assert_includes last_response.body, 'Save Changes'
  end

  def test_text_area_contains_file
    get '/about.txt/edit'
    assert_includes last_response.body, "I'm baby shabby chic live-edge lomo palo"
  end

  def test_put_file
    put '/test.txt/edit', text: 'Foo'
    expected_text = 'test.txt has been updated.'
    assert_equal(302, last_response.status)
    get last_response['Location']
    assert last_response.ok?
    assert_includes last_response.body, expected_text
  end
end
