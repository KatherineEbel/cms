# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require_relative '../cms'

class CMSTest < Minitest::Test
  include Rack::Test::Methods

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
    assert last_response.body.include?("I'm baby shabby chic")
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
    get last_response.headers['Location']
    assert last_response.ok?
    assert_includes last_response.body, expected_text

    get '/'
    refute_includes last_response.body, expected_text
  end
end
