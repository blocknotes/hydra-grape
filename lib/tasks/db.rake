require 'mongoid'
require_relative '../../app/api'

Rake::Task.define_task( :environment )

spec = Gem::Specification.find_by_name 'mongoid'
load "#{spec.gem_dir}/lib/mongoid/tasks/database.rake"
