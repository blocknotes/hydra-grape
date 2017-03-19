require 'spec_helper'
require 'digest/md5'
require_relative '../../../app/api'

describe Hydra::API do
  USER_EMAIL = 'aaa@bbb.ccc'

  def app
    Hydra::API
  end

  def sign_in
    data = { email: USER_EMAIL, encrypted_password: Digest::MD5.hexdigest( '1234' ) }
    post '/api/v1/auth/sign_in', data.to_json, 'CONTENT_TYPE' => 'application/json'
    JSON.parse( last_response.body )['token']
  end

  def sign_up
    data = { email: USER_EMAIL, password: '1234' }
    post '/api/v1/auth/sign_up', data.to_json, 'CONTENT_TYPE' => 'application/json'
  end

  context 'POST /api/v1/auth/sign_up' do
    it 'creates a new user' do
      sign_up
      basic_checks( { 'result' => 'ok' }, 201 )
    end
  end

  context 'POST /api/v1/auth/sign_in' do
    it 'creates an auth token' do
      sign_up
      sign_in
      basic_checks nil, 201
      body = JSON.parse( last_response.body )
      expect( body['result'] ).to eq 'ok'
      expect( body.include? 'token' ).to eq true
    end
  end

  context 'GET /api/v1/auth/check' do
    it 'checks if an auth token is valid' do
      sign_up
      token = sign_in
      get '/api/v1/auth/check?token=' + URI::encode( token )
      basic_checks( { 'result' => 'ok' }, 200 )
    end
  end

  context 'DELETE /api/v1/auth/sign_out' do
    it 'invalidates the auth token' do
      sign_up
      sign_in
      data = { token: Models::User.first.token }
      delete '/api/v1/auth/sign_out', data.to_json, 'CONTENT_TYPE' => 'application/json'
      basic_checks nil, 200
      body = JSON.parse( last_response.body )
      expect( body['result'] ).to eq 'ok'
      expect( Models::User.first.token ).to eq ''
    end
  end

  context 'POST /api/v1/auth/touch' do
    it 'refreshes an auth token' do
      sign_up
      token = sign_in
      user = Core::Auth.is_valid? token
      expire = user.expire
      post '/api/v1/auth/touch', { token: token }.to_json, 'CONTENT_TYPE' => 'application/json'
      basic_checks nil, 201
      user = Core::Auth.is_valid? token
      expect( expire < user.expire ).to eq true
    end
  end
end
