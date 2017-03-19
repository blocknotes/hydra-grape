require 'grape'
require 'mongoid'
require_relative 'core/auth'
require_relative 'core/projects'
require_relative 'core/collections'
require_relative 'core/items'

APP_ENV = ENV['RACK_ENV'] || 'development'
DEBUG = ENV['RACK_DEBUG'] || false

if APP_ENV == 'development'
  require 'pry'
end

module Mongoid
  module Document
    def as_json( options = {} )
      attrs = super( options )
      id = {id: attrs['_id'].to_s}
      attrs.delete('_id')
      id.merge( attrs )
    end
  end
end

module Hydra
  MESSAGE_404 = 'This is not the page you are looking for...'

  # --- Mongoid ------------------------------------------------------------- #
  Mongoid.load!( File.expand_path( '../../database.yml', __FILE__ ), APP_ENV.to_sym )

  # ------------------------------------------------------------------------- #
  class API < Grape::API
    # def self.auth_class
    #   Rack::Auth::Basic
    #   # Rack::Auth::Digest::MD5  # not checked
    # end

    include Core::Projects
    include Core::Collections
    include Core::Items
    include Core::Auth

    # --- API options ------------------------------------------------------- #
    version 'v1', using: :path # , vendor: 'develon'
    format :json
    prefix :api
    # do_not_route_options!

    # --- Core -------------------------------------------------------------- #
    Core::Projects.setup self
    Core::Collections.setup self
    Core::Items.setup self
    Core::Auth.setup self

    # --- 404 --------------------------------------------------------------- #
    route :any, '*path' do
      status 404
      { result: 'error', message_key: 'DocumentNotFound', message: MESSAGE_404 }
    end

    # --- Exceptions -------------------------------------------------------- #
    rescue_from Mongoid::Errors::DocumentNotFound do |e|
      error!( { result: 'error', message_key: 'DocumentNotFound' }, 404 )
    end
    unless DEBUG
      rescue_from :all do |e|
        case e.message
        when 'InvalidToken'
          error!( { result: 'error', message_key: e.message, message: 'Invalid token' }, 401 )
        else
          error!( { result: 'error', message_key: 'Error', message: e.message }, 500 )
        end
      end
    end
  end
end
