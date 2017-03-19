require 'mongoid'
require_relative 'project'

module Models
  class Collection
    COLLECTION = '_collections'

    include Mongoid::Document
    include Mongoid::Timestamps

    store_in collection: COLLECTION

    field :name, type: String
    field :singular, type: String
    field :columns, type: Hash
    field :actions, type: Hash
    field :auth, type: Hash

    # index({ name: 1 }, { unique: true })  # ERR -> Index ignored on: Collection, please define in the root model
    # TODO: custom check for uniqueness ?

    embedded_in :projects
  end
end
