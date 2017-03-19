require 'database_cleaner'
require 'rack/test'
require 'pry'

ENV['RACK_ENV'] = RACK_ENV = 'test' unless defined?(RACK_ENV)
# require File.expand_path(File.dirname(__FILE__) + "/../config/boot")
# Dir[File.expand_path(File.dirname(__FILE__) + "/../app/helpers/**/*.rb")].each(&method(:require))

RSpec.configure do |conf|
  conf.include Rack::Test::Methods

  conf.before(:suite) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean_with(:truncation)
  end

  conf.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end

def basic_checks( body = {}, status = 200, content_type = 'application/json' )
  expect( last_response.status ).to eq( status )
  expect( last_response.content_type ).to eq( content_type )
  expect( JSON.parse( last_response.body ) ).to eq( body ) unless body.nil?
end
