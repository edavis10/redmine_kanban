#!/usr/bin/env ruby
require 'redmine_plugin_support'

parallel_tests = (File.join(File.dirname(__FILE__), '..', 'parallel_tests','lib','tasks','parallel_tests.rake'))
if File.exists? parallel_tests
  RAILS_ROOT = File.dirname(__FILE__)
  import parallel_tests
end

Dir[File.expand_path(File.dirname(__FILE__)) + "/lib/tasks/**/*.rake"].sort.each { |ext| load ext }

RedminePluginSupport::Base.setup do |plugin|
  plugin.project_name = 'redmine_kanban'
  plugin.default_task = [:test]
  plugin.tasks = [:doc, :release, :clean, :test, :db, :cucumber, :stats, :metrics]
  # TODO: gem not getting this automaticly
  plugin.redmine_root = File.expand_path(File.dirname(__FILE__) + '/../../../')
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "redmine_kanban"
    s.summary = "The Redmine Kanban plugin is used to manage issues according to the Kanban system of project management."
    s.email = "edavis@littlestreamsoftware.com"
    s.homepage = "https://projects.littlestreamsoftware.com/projects/redmine-kanban"
    s.description = "The Redmine Kanban plugin is used to manage issues according to the Kanban system of project management."
    s.authors = ["Eric Davis"]
    s.files =  FileList[
                        "[A-Z]*",
                        "init.rb",
                        "rails/init.rb",
                        "{bin,generators,lib,test,app,assets,config,lang}/**/*",
                        'lib/jeweler/templates/.gitignore'
                       ]
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler, or one of its dependencies, is not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

