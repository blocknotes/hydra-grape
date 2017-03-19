require 'grape'
require 'mongoid'
require 'digest/md5'
require_relative '../models/user'

module Core
  module Auth
    EXPIRE_IN = 3600  # seconds
    HTTP_AUTH_TOKEN = 'HTTP_AUTH_TOKEN'

    def self.setup( api )
      api.resource :auth do
        # --- LOGIN --------------------------------------------------------- #
        desc 'Sign in'
        post 'sign_in' do
          data = params.to_h
          error!( 'MissingParameters', 400 ) unless data['email'] && data['encrypted_password']
          user = Models::User.where( email: data['email'], encrypted_password: data['encrypted_password'] ).first
          if user
            # TODO: generate a better token
            user.token = Digest::MD5.hexdigest( user.email + Time.now.to_i.to_s )
            user.expire = Time.now + Core::Auth::EXPIRE_IN
            user.save
            body( { result: 'ok', token: user.token } )
          else
            error!( 'InvalidAccess', 401 )
          end
        end

        # --- LOGOUT -------------------------------------------------------- #
        desc 'Sign out'
        delete 'sign_out' do
          data = params.to_h
          error!( 'MissingParameters', 400 ) unless data['token']
          user = Models::User.where( token: data['token'] ).first
          if user
            user.token = ''
            user.expire = Time.now
            user.save
            body( { result: 'ok' } )
          else
            error!( 'InvalidAccess', 401 )
          end
        end

        # --- REGISTER ------------------------------------------------------ #
        desc 'Sign up'
        post 'sign_up' do
          data = params.to_h
          error!( 'MissingParameters', 400 ) unless data['email'] && data['password']
          Models::User.create( email: data['email'], encrypted_password: Digest::MD5.hexdigest( data['password'] ) )
          body( { result: 'ok' } )
        end

        # --- REFRESH ------------------------------------------------------- #
        desc 'Touch'
        post 'touch' do
          data = params.to_h
          error!( 'MissingParameters', 400 ) unless data['token']
          if( user = Auth.is_valid?( data['token'] ) )
            user.expire = Time.now + Core::Auth::EXPIRE_IN
            user.save
            body( { result: 'ok', expire: user.expire } )
          else
            error!( 'InvalidAccess', 401 )
          end
        end

        # --- CHECK --------------------------------------------------------- #
        desc 'Is valid?'
        get 'check' do
          data = params.to_h
          error!( 'MissingParameters', 400 ) unless data['token']
          if Auth.is_valid?( data['token'] )
            body( { result: 'ok' } )
          else
            error!( 'InvalidAccess', 401 )
          end
        end
      end

      ## Basic Auth
      # if defined? api.auth_class
      #   Grape::Middleware::Auth::Strategies.add( :authorize, api.auth_class, ->(options) { [options[:realm]] } )
      #   api.auth :authorize, { realm: 'Test Api' } do |username, password|
      #     [ { 'user1' => 'password1' } ].include?( { username => password } )
      #   end
      # end
    end

    def self.is_valid?( token )
      # binding.pry
      Models::User.where( token: token, :expire.gte => Time.now ).first
    end

    def self.authorize( env, context, auth_info )
      if auth_info
        if env[HTTP_AUTH_TOKEN]
          raise 'InvalidToken' unless Auth.is_valid?( env[HTTP_AUTH_TOKEN] )
        else
          raise 'InvalidToken'
        end
      end
    end
  end
end
