require 'spec_helper'
require_relative '../../../app/api'

describe Hydra::API do
  def app
    Hydra::API
  end

  # before do
  # end

  context 'GET /api/v1/projects' do
    it 'returns an empty list' do
      get '/api/v1/projects'
      basic_checks( { 'projects' => [] } )
    end
  end

  context 'POST /api/v1/projects' do
    it 'creates a new project' do
      project = 'A test project'
      data = { name: project, code: 'test' }
      post '/api/v1/projects', data.to_json, 'CONTENT_TYPE' => 'application/json'
      basic_checks nil, 201
      body = JSON.parse( last_response.body )
      expect( body['result'] ).to eq 'ok'
      expect( body.include? 'project' ).to be true
      expect( body['project'].include? 'id' ).to be true
      expect( body['project']['name'] ).to eq project
    end
  end

  context 'PUT /api/v1/projects' do
    it 'updates a project' do
      project = 'A test project'
      data = { name: rand( 100 ).to_s, code: 'test' }
      post '/api/v1/projects', data.to_json, 'CONTENT_TYPE' => 'application/json'
      id = JSON.parse( last_response.body )['project']['id']
      put '/api/v1/projects/' + id, { name: project }.to_json, 'CONTENT_TYPE' => 'application/json'
      basic_checks nil, 200
      body = JSON.parse( last_response.body )
      expect( body['result'] ).to eq 'ok'
      expect( body.include? 'project' ).to be true
      expect( body['project']['name'] ).to eq project
    end
  end

  context 'DELETE /api/v1/projects' do
    it 'deletes a project' do
      data = { name: rand( 100 ).to_s, code: 'test' }
      post '/api/v1/projects', data.to_json, 'CONTENT_TYPE' => 'application/json'
      id = JSON.parse( last_response.body )['project']['id']
      delete '/api/v1/projects/' + id, 'CONTENT_TYPE' => 'application/json'
      basic_checks nil, 200
      body = JSON.parse( last_response.body )
      expect( body['result'] ).to eq 'ok'
    end
  end

  context 'GET /api/v1/a_random_route' do
    it 'returns 404' do
      get '/api/v1/a_random_route'
      basic_checks( { 'result' => 'error', 'message_key' => 'DocumentNotFound', 'message' => Hydra::MESSAGE_404 }, 404 )
    end
  end
end
