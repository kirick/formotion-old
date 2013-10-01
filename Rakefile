$:.unshift("/Library/RubyMotion/lib")
require 'motion/project'
require "bundler/gem_tasks"
require "bundler/setup"

$:.unshift("./lib/")
require './lib/formotion'

Motion::Project::App.setup do |app|
  # Use `rake config' to see complete project settings.
  app.name = 'Formotion'
  app.vendor_project('vendor/ActionSheetPicker', :static)
end

namespace :spec do
  task :units do
    App.config.spec_mode = true
    spec_files = App.config.spec_files
    functional_files = Dir.glob('./spec/functional/**/*.rb')
    spec_files -= functional_files
    App.config.instance_variable_set("@spec_files", spec_files)
    Rake::Task["simulator"].invoke
  end

  task :functionals do
    App.config.spec_mode = true
    spec_files = App.config.spec_files
    row_type_files = Dir.glob('./spec/row_type/**/*.rb')
    spec_files -= row_type_files
    App.config.instance_variable_set("@spec_files", spec_files)
    Rake::Task["simulator"].invoke
  end
end
