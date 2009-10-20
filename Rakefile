#!/usr/bin/env ruby
require 'redmine_plugin_support'

Dir[File.expand_path(File.dirname(__FILE__)) + "/lib/tasks/**/*.rake"].sort.each { |ext| load ext }

RedminePluginSupport::Base.setup do |plugin|
  plugin.project_name = 'redmine_kanban'
  plugin.default_task = [:test, :features]
  plugin.tasks = [:doc, :release, :clean, :test, :cucumber]
  # TODO: gem not getting this automaticly
  plugin.redmine_root = File.expand_path(File.dirname(__FILE__) + '/../../../')
end

task :environment do
  require(File.join(File.expand_path(File.dirname(__FILE__) + '/../../../config'), 'environment'))
end
begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "redmine_kanban"
    s.summary = "The Redmine Kanban plugin is used to manage issues according to the Kanban system of project management."
    s.email = "edavis@littlestreamsoftware.com"
    s.homepage = "https://projects.littlestreamsoftware.com/projects/TODO"
    s.description = "The Redmine Kanban plugin is used to manage issues according to the Kanban system of project management."
    s.authors = ["Eric Davis"]
    s.rubyforge_project = "redmine_kanban" # TODO
    s.files =  FileList[
                        "[A-Z]*",
                        "init.rb",
                        "rails/init.rb",
                        "{bin,generators,lib,test,app,assets,config,lang}/**/*",
                        'lib/jeweler/templates/.gitignore'
                       ]
  end
  Jeweler::GemcutterTasks.new
  Jeweler::RubyforgeTasks.new do |rubyforge|
    rubyforge.doc_task = "rdoc"
  end
rescue LoadError
  puts "Jeweler, or one of its dependencies, is not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

