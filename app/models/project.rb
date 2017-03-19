require 'mongoid'
require_relative 'collection'

module Models
  class Project
    COLLECTION = '_projects'

    include Mongoid::Document
    include Mongoid::Timestamps

    store_in collection: COLLECTION

    field :name, type: String
    field :code, type: String
    field :url, type: String
    # field :collections, type: Hash

    embeds_many :collections

    # TODO: users - embed? n-n?

    index({ 'code' => 1 }, { unique: true })
    # index({ 'collections.name' => 1 }, { unique: true })
    # index( { code: 1, 'collections.name': 1 }, { unique: true, sparse: true } )
    # index({ _id: 1, 'collections.name': 1 }, { unique: true })  # no effect
  end
end
