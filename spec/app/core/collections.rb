require 'spec_helper'
require_relative '../../../app/api'

describe Hydra::API do
  def app
    Hydra::API
  end

  before do
    @project = Models::Project.new( name: 'A test project', code: 'prj' )
    @project.save
  end

  context 'GET /api/v1/collections/:project_id' do
    it 'returns an empty list' do
      get '/api/v1/collections/' + @project.id
      basic_checks( { 'collections' => [] } )
    end
  end

  context 'POST /api/v1/collections/:project_id' do
    it 'creates a collection with some columns' do
      expect( Models::Project.first.collections.count ).to eq 0
      col_name = 'articles'
      col_singular = 'article'
      data = { name: col_name, singular: col_singular, columns: { title: 'String', description: 'String', position: 'Float', published: 'Boolean', dt: 'DateTime' } }
      post '/api/v1/collections/' + @project.id, data.to_json, 'CONTENT_TYPE' => 'application/json'
      basic_checks nil, 201
      collections = Models::Project.first.collections
      expect( collections.count ).to eq 1
      expect( collections.first.name ).to eq col_name
      expect( collections.first.singular ).to eq col_singular
    end
  end

  context 'POST /api/v1/collections/:project_id (2)' do
    it 'creates a collection with some actions' do
      expect( Models::Project.first.collections.count ).to eq 0
      col_name = 'articles'
      col_singular = 'article'
      act_list = [ 'title' ]
      act_read = [ 'title', 'description' ]
      data = { name: col_name, singular: col_singular, columns: { title: 'String', description: 'String' }, actions: { list: [ 'title' ], read: [ 'title', 'description' ] } }
      post '/api/v1/collections/' + @project.id, data.to_json, 'CONTENT_TYPE' => 'application/json'
      basic_checks nil, 201
      collection = Models::Project.first.collections.first
      expect( collection.actions['list'] ).to eq act_list
      expect( collection.actions['read'] ).to eq act_read
    end
  end

  context 'GET /api/v1/collections/:project_id/:id' do
    it 'read a collection' do
      @project.collections << Models::Collection.new( name: 'articles', singular: 'article', columns: { title: 'String' } )
      @project.save
      id = Models::Project.first.collections.first.id
      get '/api/v1/collections/' + @project.id + '/' + id
      basic_checks nil, 200
      body = JSON.parse( last_response.body )
      expect( body.include? 'collection' ).to be true
    end
  end

  context 'PUT /api/v1/collections/:project_id/:id' do
    it 'updates a collection' do
      @project.collections << Models::Collection.new( name: 'articles', singular: 'article', columns: { title: 'String' } )
      @project.save
      id = Models::Project.first.collections.first.id
      data = { name: 'art', columns: { description: 'String' } }
      put '/api/v1/collections/' + @project.id + '/' + id, data.to_json, 'CONTENT_TYPE' => 'application/json'
      basic_checks nil, 200
      collection = Models::Project.first.collections.first
      expect( collection.name ).to eq 'art'
      expect( collection.columns ).to eq( { 'description' => 'String' } )
    end
  end

  context 'DELETE /api/v1/collections/:project_id/:id' do
    it 'deletes a collection' do
      expect( Models::Project.first.collections.count ).to eq 0
      @project.collections << Models::Collection.new( name: 'articles', singular: 'article', columns: { title: 'String' } )
      @project.save
      expect( Models::Project.first.collections.count ).to eq 1
      id = Models::Project.first.collections.first.id
      delete '/api/v1/collections/' + @project.id + '/' + id, 'CONTENT_TYPE' => 'application/json'
      basic_checks nil, 200
      expect( Models::Project.first.collections.count ).to eq 0
    end
  end
end
