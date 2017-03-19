require 'spec_helper'
require_relative '../../../app/api'

describe Hydra::API do
  ITEMS_PRJ  = 'prj'
  ITEMS_COL  = 'articles'
  ITEMS_COL_ = 'article'
  ITEMS_BASE_PATH = '/api/v1/items/' + ITEMS_PRJ + '_' + ITEMS_COL

  def app
    Hydra::API
  end

  before do
    @project = Models::Project.new( name: 'A test project', code: ITEMS_PRJ )
    @project.save
    data = { name: ITEMS_COL, singular: ITEMS_COL_, columns: { title: 'String', description: 'String', position: 'Float', published: 'Boolean', dt: 'DateTime' } }
    post '/api/v1/collections/' + @project.id, data.to_json, 'CONTENT_TYPE' => 'application/json'
  end

  context 'GET /api/v1/items/:code_model' do
    it 'returns an empty list' do
      get ITEMS_BASE_PATH
      basic_checks( { 'result' => 'ok', 'articles' => [] } )
    end
  end

  context 'POST /api/v1/items/:code_model' do
    it 'creates an item' do
      expect( Models::PrjArticle.count ).to eq 0
      title = 'A test article'
      desc = 'Just a desc'
      data = { data: { title: title, description: desc } }
      post ITEMS_BASE_PATH, data.to_json, 'CONTENT_TYPE' => 'application/json'
      basic_checks nil, 201
      expect( Models::PrjArticle.count ).to eq 1
      article = Models::PrjArticle.first
      expect( article.title ).to eq title
      expect( article.description ).to eq desc
    end
  end

  context 'READ /api/v1/items/:code_model/:id' do
    it 'read an item' do
      Models::PrjArticle.create( { title: 'A test article', description: 'Just a desc' } )
      get ITEMS_BASE_PATH + '/' + Models::PrjArticle.first.id.to_s, 'CONTENT_TYPE' => 'application/json'
      basic_checks nil, 200
      body = JSON.parse( last_response.body )
      expect( body.include? 'article' ).to be true
      expect( body['article']['title'] ).to eq 'A test article'
    end
  end

  context 'PUT /api/v1/items/:code_model/:id' do
    it 'updates an item' do
      Models::PrjArticle.create( { title: 'A test article', description: 'Just a desc' } )
      title = 'An updated article'
      desc = 'Just another desc'
      data = { data: { title: title, description: desc } }
      put ITEMS_BASE_PATH + '/' + Models::PrjArticle.first.id.to_s, data.to_json, 'CONTENT_TYPE' => 'application/json'
      basic_checks( { 'result' => 'ok' }, 200 )
    end
  end

  context 'DELETE /api/v1/items/:code_model/:id' do
    it 'deletes an item' do
      Models::PrjArticle.create( { title: 'A test article', description: 'Just a desc' } )
      expect( Models::PrjArticle.count ).to eq 1
      delete ITEMS_BASE_PATH + '/' + Models::PrjArticle.first.id, 'CONTENT_TYPE' => 'application/json'
      basic_checks( { 'result' => 'ok' }, 200 )
      expect( Models::PrjArticle.count ).to eq 0
    end
  end
end
