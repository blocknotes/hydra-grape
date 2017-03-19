require 'mongoid'
require_relative 'collection'

module Models
  class User
    COLLECTION = '_users'

    include Mongoid::Document
    include Mongoid::Timestamps

    store_in collection: COLLECTION

    field :email, type: String
    field :encrypted_password, type: String
    field :token, type: String
    field :expire, type: DateTime

    index({ 'email' => 1 }, { unique: true })
    index({ 'token' => 1 }, { unique: true })
  end
end
