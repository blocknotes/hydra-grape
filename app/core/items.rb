require 'grape'
require 'mongoid'
require_relative 'projects'
require_relative 'utils'

module Core
  module Items
    KEY_INVALID_REQUEST = 'InvalidRequest'
    MESSAGE_INVALID_REQUEST = 'Invalid request'
    TYPES = [ 'Array','BigDecimal','Boolean','Date','DateTime','Float','Hash','Integer','BSON::ObjectId','BSON::Binary','Range','Regexp','String','Symbol','Time','TimeWithZone' ].freeze

    @@schema = {}

    # TODO: alternative: write models to files
    def self.update_schema( code = nil, name = nil )
      if code
        # TODO: delete also classes
        # ES: Object.send( :remove_const, 'Test2' )
        if name
          @@schema.delete( ( code + '_' + name ).to_sym )
        else
          c = code + '_'
          @@schema.each { |k, v| @@schema.delete( k ) if k.to_s.starts_with? c }
        end
      end
      Models::Project.all.each do |project|
        project.collections.each do |collection|
          code_model = project.code + '_' + collection.name
          if !@@schema[code_model.to_sym]
            # Dynamically create a model class
            klass = Class.new do
              include Mongoid::Document
              store_in collection: code_model
            end
            k = Utils.camelize( project.code + '_' + collection.singular )
            Models.const_get( k ) rescue Models.const_set( k, klass )
            # Dinamically add columns
            collection.columns.each do |f, data|
              if TYPES.include? data
                klass.class_eval { field f.to_sym, type: Object.const_get( data ) }
              elsif data == 'embeds_one'
                klass.class_eval { embeds_one f.to_sym }
              elsif data == 'embeds_many'
                klass.class_eval { embeds_many f.to_sym }
              elsif data == 'embedded_in'
                klass.class_eval { embedded_in f.to_sym }
              elsif data == 'has_one'
                klass.class_eval { has_one f.to_sym }
              elsif data == 'has_many'
                klass.class_eval { has_many f.to_sym }
              elsif data == 'has_and_belongs_to_many'
                klass.class_eval { has_and_belongs_to_many f.to_sym }
              else
                # TODO: error log
              end
            end
            klass.const_set 'NAME', collection.singular
            klass.const_set 'PLURAL', collection.name
            klass.const_set 'ACTIONS', ( defined?( collection.actions ) && collection.actions ? collection.actions : {} )
            klass.const_set 'AUTH', ( defined?( collection.auth ) && collection.auth ? collection.auth : {} )
            @@schema[code_model.to_sym] ||= klass
          end
        end
      end
      # puts @@schema.inspect if DEBUG
      @@schema
    end

    def self.setup( api )
      update_schema
      # Prepare the routes
      api.resource :items do
        route_param :code_model do
          # --- CREATE ---------------------------------------------------- #
          desc 'Create an item'
          post do
            if( code_model = @@schema[params[:code_model].to_sym] )
              data = params[:data].to_h
              if code_model::ACTIONS[:create]
                # filter parameters
                data.keep_if { |k, v| code_model::ACTIONS[:create].include?( k ) }
              end
              data.delete( 'id' )
              data.delete( '_id' )
              result = code_model.create data
              body( { result: result ? :ok : :error, code_model::NAME => result } )
            else
              status 400
              body( { result: :error, message_key: KEY_INVALID_REQUEST, message: MESSAGE_INVALID_REQUEST } )
            end
          end

          route_param :id do
            # --- READ ---------------------------------------------------- #
            desc 'Read item'
            get do
              if( code_model = @@schema[params[:code_model].to_sym] )
                if code_model::ACTIONS[:read]
                  result  = code_model.only( code_model::ACTIONS[:read] ).find_by id: params[:id]
                else
                  result = code_model.find_by id: params[:id]
                end
                body( { result: result ? :ok : :error, code_model::NAME => result } )
              else
                status 400
                body( { result: :error, message_key: KEY_INVALID_REQUEST, message: MESSAGE_INVALID_REQUEST } )
              end
            end

            # --- UPDATE -------------------------------------------------- #
            desc 'Update item'
            put do
              if( code_model = @@schema[params[:code_model].to_sym] )
                result = code_model.find_by id: params[:id]
                data = params[:data].to_h
                if code_model::ACTIONS[:update]
                  # filter parameters
                  data.keep_if { |k, v| code_model::ACTIONS[:update].include?( k ) }
                end
                data.delete( 'id' )
                data.delete( '_id' )
                body( { result: result.update( data ) ? :ok : :error } )
              else
                status 400
                body( { result: :error, message_key: KEY_INVALID_REQUEST, message: MESSAGE_INVALID_REQUEST } )
              end
            end

            # --- DELETE -------------------------------------------------- #
            desc 'Delete item'
            delete do
              if( code_model = @@schema[params[:code_model].to_sym] )
                item = code_model.find_by id: params[:id]
                result = item.destroy
                body( { result: result ? :ok : :error } )
              else
                status 400
                body( { result: :error, message_key: KEY_INVALID_REQUEST, message: MESSAGE_INVALID_REQUEST } )
              end
            end
          end

          # --- LIST ------------------------------------------------------ #
          desc 'List items'
          get do
            if( code_model = @@schema[params[:code_model].to_sym] )
              Auth.authorize env, code_model, code_model::AUTH[:list]
              results = code_model::ACTIONS[:list] ? code_model.only( code_model::ACTIONS[:list] ) : code_model.all
              header 'X-Total-Count', code_model.count.to_s
              body( { result: :ok, code_model::PLURAL => results } )
            else
              status 400
              body( { result: :error, message_key: KEY_INVALID_REQUEST, message: MESSAGE_INVALID_REQUEST } )
            end
          end
        end
      end
    end
  end
end
