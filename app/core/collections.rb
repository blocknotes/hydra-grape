require 'grape'
require 'mongoid'
require_relative 'items'
require_relative 'utils'

module Core
  module Collections
    # def self.list # ( update = false )
    #   @@collections ||= Mongoid.default_client.collections.map &:name
    # end

    def self.setup( api )
      api.resource :collections do
        route_param :project_id do
          # --- CREATE ------------------------------------------------------ #
          desc 'Create a new collection'
          params do
            requires :name, type: String, desc: 'Collection name (plural)'
            requires :singular, type: String, desc: 'Collection name (singular)'
          end
          post do
            Auth.authorize env, Models::Project, false
            project = Models::Project.find params[:project_id]
            name = params[:name].downcase

            collection = Models::Collection.new( name: name, singular: params[:singular].downcase, columns: params[:columns], actions: params[:actions], auth: params[:auth] )
            project.collections.push collection
            project.save

            schema = Items.update_schema( project.code, name )
            klass = schema[( project.code + '_' + name ).to_sym]

            # alternative: Mongoid.default_client.database.command( eval: 'db.createCollection("a_test")' )

            # col_name = project.code + '_' + name
            # collection = Collections.const_set Utils.camelize( col_name ), klass

            # klass.new().save( validate: false )  # Create a record to create the collection
            # klass.delete_all  # Clean the collection

            body( { result: klass ? :ok : :error, collection: klass } )
          end

          route_param :id do
            # --- READ ------------------------------------------------------ #
            desc 'Read a collection'
            get do
              Auth.authorize env, Models::Project, false
              project = Models::Project.find params[:project_id]
              collection = project.collections.find params[:id]
              body( { result: :ok, collection: collection } )
            end

            # --- UPDATE ---------------------------------------------------- #
            desc 'Update a collection'
            put do
              Auth.authorize env, Models::Project, false
              project = Models::Project.find params[:project_id]
              collection = project.collections.find params[:id]
              data = params.to_h
              data.keep_if { |k, v| [ 'name', 'singular', 'columns', 'actions', 'auth' ].include? k }
              # data.delete( 'id' )
              # data.delete( '_id' )
              ret = collection.update_attributes data
              Items.update_schema project.code
              body( { result: ret ? :ok : :error, collection: collection } )
            end

            # --- DELETE ---------------------------------------------------- #
            desc 'Delete a collection'
            delete do
              Auth.authorize env, Models::Project, false
              project = Models::Project.find params[:project_id]
              collection = project.collections.find params[:id]
              col_name = project.code + '_' + collection.name
              Mongoid.default_client.collections.each do |col|
                if col.name == col_name
                  col.drop
                  break
                end
              end
              result = collection.destroy
              Items.update_schema project.code, collection.name
              body( { result: result ? :ok : :error } )
            end
          end

          # --- LIST -------------------------------------------------------- #
          desc 'Get collections'
          get do
            Auth.authorize env, Models::Project, false
            project = Models::Project.find params[:project_id]
            # code = project.code + '_'
            # collections = Collections.list.map { |col| col if col.starts_with? code }.compact
            header 'X-Total-Count', project.collections.count.to_s
            body( { collections: project.collections } )
          end
        end
      end
    end
  end
end
