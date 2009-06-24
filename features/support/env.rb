# Sets up the Rails environment for Cucumber
ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + '/../../../../../config/environment')
require 'cucumber/rails/world'
Cucumber::Rails.use_transactional_fixtures

require 'webrat/rails'

# Comment out the next two lines if you're not using RSpec's matchers (should / should_not) in your steps.
# require 'cucumber/rails/rspec'
# require 'webrat/rspec-rails'

require 'ruby-debug'

# Machinist and it's data
require 'faker'
require 'machinist'

require File.expand_path(File.dirname(__FILE__) + '/../../test/blueprints/blueprint')

# Testing emails
gem 'bmabey-email_spec', '0.1.2'
require 'email_spec'
require 'email_spec/cucumber'


# require the entire app if we're running under coverage testing,
# so we measure 0% covered files in the report
#
# http://www.pervasivecode.com/blog/2008/05/16/making-rcov-measure-your-whole-rails-app-even-if-tests-miss-entire-source-files/
if defined?(Rcov)
  all_app_files = Dir.glob('{app,lib}/**/*.rb')
  all_app_files.each{|rb| require rb}
end
