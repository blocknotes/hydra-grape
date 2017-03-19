require 'grape'
require 'mongoid'

require_relative '../models/project'

module Core
  module Utils
    def self.camelize( str )
      str.split( '_' ).map( &:capitalize ).join
    end
  end
end
