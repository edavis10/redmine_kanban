# Redmine Shams
Sham.mail { Faker::Internet.email }
Sham.name { Faker::Name.name }
Sham.firstname { Faker::Name.first_name }
Sham.lastname { Faker::Name.last_name }
Sham.login { Faker::Internet.user_name }
Sham.project_name { Faker::Company.name }
Sham.identifier { Faker::Internet.domain_word.downcase }
Sham.message { Faker::Company.bs }
Sham.position {|index| index }
Sham.single_name { Faker::Internet.domain_word.capitalize }


# Plugin Shams
Sham.permissions(:unique => false) {
  [
  ]
}

# Redmine specific blueprints
User.blueprint do
  mail
  firstname
  lastname
  login
end

User.blueprint(:administrator) do
  mail
  firstname
  lastname
  login
  admin { true }
end

Project.blueprint do
  name { Sham.project_name }
  identifier
  enabled_modules
end

def make_project_with_enabled_modules(attributes = {})
  Project.make(attributes) do |project|
    ['issue_tracking'].each do |name|
      project.enabled_modules.make(:name => name)
    end
  end
end

EnabledModule.blueprint do
  project
  name { 'issue_tracking' }
end

Member.blueprint do
  project
  user
  role
end

Role.blueprint do
  name { Sham.identifier }
  position
  permissions
end

IssueStatus.blueprint do
  name
  is_closed { false }
  is_default { false }
  position
end

def make_tracker_for_project(project, attributes = {})
  Tracker.make(attributes) do |tracker|
    project.trackers << tracker
    project.save!
  end
end

Tracker.blueprint do
  name { Sham.single_name }
  position { Sham.position }
end

def assign_tracker_to_project(tracker, project)
  project.trackers << tracker
  project.save!
end

Enumeration.blueprint do
  name { Sham.single_name }
  opt { 'IPRI' }
end

IssuePriority.blueprint do
  name { Sham.single_name }
end


Issue.blueprint do
  project
  subject { Sham.message }
  tracker { Tracker.make }
  description { Sham.message }
  priority { IssuePriority.make}
  status { IssueStatus.make }
  author { User.make }
end
