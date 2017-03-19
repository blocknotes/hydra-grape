require 'grape'
require 'mongoid'
require_relative '../models/project'
require_relative 'auth'
require_relative 'collections'
require_relative 'items'
require_relative 'utils'

module Core
  module Projects
    # @@collections = {}

    # def self.collections
    #   @@collections
    # end

    def self.setup( api )
      api.resource :projects do
        # api.before do |env|
        #   Auth.authorize env
        # end

        # options do
        #   header 'Allow', 'OPTIONS, POST, GET, HEAD'
        #   header 'Content-Type', 'application/json'
        #   status 200
        #   # status 204
        #   ''
        # end

        # --- CREATE -------------------------------------------------------- #
        desc 'Create a new project'
        params do
          requires :name, type: String, desc: 'Project name'
          requires :code, type: String, regexp: /\A[a-z0-9]+\z/, desc: 'Project code (only chars or numbers)'
          optional :url, type: String, desc: 'Project URL'
        end
        post do
          Auth.authorize env, Models::Project, false
          data = params.to_h
          data.keep_if { |k, v| [ 'name', 'code', 'url' ].include? k }
          project = Models::Project.create data
          Items.update_schema
          body( { result: project ? :ok : :error, project: project } )
        end

        # params do
        #   requires :id, type: BSON::ObjectId, desc: 'Project id'
        # end
        route_param :id do
          # --- READ -------------------------------------------------------- #
          desc 'Read a project'
          get do
            Auth.authorize env, Models::Project, false
            project = Models::Project.find( params[:id] )
            code = project.code + '_'
            # project[:collections] = Collections.list.map { |col| col if col.starts_with? code }.compact
            body( { result: :ok, project: project } )
          end

          # --- UPDATE ------------------------------------------------------ #
          desc 'Update a project'
          params do
            optional :name, type: String, desc: 'Project name'
            optional :code, type: String, regexp: /\A[a-z0-9]+\z/, desc: 'Project code (only chars or numbers)'
            optional :url, type: String, desc: 'Project URL'
          end
          put do
            Auth.authorize env, Models::Project, false
            project = Models::Project.find params[:id]
            data = params.to_h
            data.keep_if { |k, v| [ 'name', 'code', 'url' ].include? k }
            ret = project.update_attributes data
            Items.update_schema project.code if params[:code] && params[:code] != project.code
            body( { result: ret ? :ok : :error, project: project } )
          end

          # --- DELETE ------------------------------------------------------ #
          desc 'Delete a project'
          delete do
            Auth.authorize env, Models::Project, false
            project = Models::Project.find_by id: params[:id]
            code = project.code
            result = project.destroy
            Items.update_schema project.code
            # TODO: destroy project collections
            body( { result: result ? :ok : :error } )
          end
        end

        # --- LIST ---------------------------------------------------------- #
        desc 'List of projects'
        get do
          Auth.authorize env, Models::Project, false
          header 'X-Total-Count', Models::Project.count.to_s
          body( { projects: Models::Project.all } )
        end
      end
    end
  end
end
