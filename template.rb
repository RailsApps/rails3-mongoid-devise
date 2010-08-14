# Application Generator Template
# Modifies a Rails app to use Mongoid and Devise
# Usage: rails new app_name -m http://github.com/fortuity/rails3-mongoid-devise/raw/master/template.rb

# More info: http://github.com/fortuity/rails3-mongoid-devise/

# If you are customizing this template, you can use any methods provided by Thor::Actions
# http://rdoc.info/rdoc/wycats/thor/blob/f939a3e8a854616784cac1dcff04ef4f3ee5f7ff/Thor/Actions.html
# and Rails::Generators::Actions
# http://github.com/rails/rails/blob/master/railties/lib/rails/generators/actions.rb

puts "Modifying a new Rails app to use Mongoid and Devise..."
puts "Any problems? See http://github.com/fortuity/rails3-mongoid-devise/issues"

if yes?('Would you like to use the Haml template system? (yes/no)')
  haml_flag = true
else
  haml_flag = false
end

puts "setting up source control with 'git'..."
# specific to Mac OS X
append_file '.gitignore' do
  '.DS_Store'
end
git :init
git :add => '.'
git :commit => "-m 'Initial commit of unmodified new Rails app'"

puts "removing unneeded files..."
run 'rm config/database.yml'
run 'rm public/index.html'
run 'rm public/favicon.ico'
run 'rm public/images/rails.png'
run 'rm README'
run 'touch README'

puts "ban spiders from your site..."
gsub_file 'public/robots.txt', /# User-Agent/, 'User-Agent'
gsub_file 'public/robots.txt', /# Disallow/, 'Disallow'

if haml_flag
  puts "setting up Gemfile for Haml..."
  append_file 'Gemfile', "\n# Bundle gems needed for Haml\n"
  gem 'haml', '3.0.14'
  gem "rails3-generators", :group => :development
end

puts "setting up Gemfile for Mongoid..."
gsub_file 'Gemfile', /gem \'sqlite3-ruby/, '# gem \'sqlite3-ruby'
append_file 'Gemfile', "\n# Bundle gems needed for Mongoid\n"
gem 'mongoid', '2.0.0.beta.16'
gem 'bson_ext', '1.0.4'

puts "installing Mongoid gems (takes a few minutes!)..."
run 'bundle install'

puts "creating 'config/mongoid.yml' Mongoid configuration file..."
run 'rails generate mongoid:config'

puts "modifying 'config/application.rb' file for Mongoid..."
gsub_file 'config/application.rb', /require 'rails\/all'/ do
<<-RUBY
# If you are deploying to Heroku and MongoHQ,
# you supply connection information here.
require 'uri'
if ENV['MONGOHQ_URL']
  mongo_uri = URI.parse(ENV['MONGOHQ_URL'])
  ENV['MONGOID_HOST'] = mongo_uri.host
  ENV['MONGOID_PORT'] = mongo_uri.port.to_s
  ENV['MONGOID_USERNAME'] = mongo_uri.user
  ENV['MONGOID_PASSWORD'] = mongo_uri.password
  ENV['MONGOID_DATABASE'] = mongo_uri.path.gsub('/', '')
end

require 'mongoid/railtie'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'active_resource/railtie'
require 'rails/test_unit/railtie'
RUBY
end
if haml_flag
gsub_file 'config/application.rb', /# Configure the default encoding used in templates for Ruby 1.9./ do
<<-RUBY
config.generators do |g|
      g.orm             :mongoid
      g.template_engine :haml
    end
    
    # Configure the default encoding used in templates for Ruby 1.9.
RUBY
end
else
  gsub_file 'config/application.rb', /# Configure the default encoding used in templates for Ruby 1.9./ do
  <<-RUBY
  config.generators do |g|
        g.orm             :mongoid
      end

      # Configure the default encoding used in templates for Ruby 1.9.
  RUBY
  end
end

puts "prevent logging of passwords"
gsub_file 'config/application.rb', /:password/, ':password, :password_confirmation'

puts "setting up Gemfile for Devise..."
append_file 'Gemfile', "\n# Bundle gem needed for Devise\n"
gem 'devise', '1.1.1'

puts "installing Devise gem (takes a few minutes!)..."
run 'bundle install'

puts "creating 'config/initializers/devise.rb' Devise configuration file..."
run 'rails generate devise:install'

puts "modifying environment configuration files for Devise..."
gsub_file 'config/environments/development.rb', /# Don't care if the mailer can't send/, '### ActionMailer Config'
gsub_file 'config/environments/development.rb', /config.action_mailer.raise_delivery_errors = false/ do
<<-RUBY
config.action_mailer.default_url_options = { :host => 'localhost:3000' }
  # A dummy setup for development - no deliveries, but logged
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = false
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default :charset => "utf-8"
RUBY
end
gsub_file 'config/environments/production.rb', /config.i18n.fallbacks = true/ do
<<-RUBY
config.i18n.fallbacks = true

  config.action_mailer.default_url_options = { :host => 'yourhost.com' }
  ### ActionMailer Config
  # Setup for production - deliveries, no errors raised
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.default :charset => "utf-8"
RUBY
end

puts "creating a User model and modifying routes for Devise..."
run 'rails generate devise User'

puts "adding a 'name' attribute to the User model"
gsub_file 'app/models/user.rb', /end/ do
<<-RUBY
  field :name
  validates_presence_of :name
  validates_uniqueness_of :name, :email, :case_sensitive => false
  attr_accessible :name, :email, :password, :password_confirmation
end
RUBY
end

puts "creating a default user"
append_file 'db/seeds.rb' do <<-FILE
puts 'SETTING UP DEFAULT USER LOGIN'
user = User.create! :name => 'First User', :email => 'user@test.com', :password => 'please', :password_confirmation => 'please'
puts 'New user created: ' << user.name
FILE
end
run 'rake db:seed'

puts "create a home controller and view"
generate(:controller, "home index")
gsub_file 'config/routes.rb', /get \"home\/index\"/, 'root :to => "home#index"'

puts "set up a simple demonstration of Devise"
gsub_file 'app/controllers/home_controller.rb', /def index/ do
<<-RUBY
def index
    @users = User.all
RUBY
end

if haml_flag
  run 'rm app/views/home/index.html.haml'
  # we have to use single-quote-style-heredoc to avoid interpolation
  create_file 'app/views/home/index.html.haml' do 
<<-'FILE'
- @users.each do |user|
  %p User: #{link_to user.name, user}
FILE
  end
else
  append_file 'app/views/home/index.html.erb' do <<-FILE
<% @users.each do |user| %>
  <p>User: <%=link_to user.name, user %></p>
<% end %>
  FILE
  end
end

generate(:controller, "users show")
gsub_file 'config/routes.rb', /get \"users\/show\"/, '#get \"users\/show\"'
gsub_file 'config/routes.rb', /devise_for :users/ do
<<-RUBY
devise_for :users
  resources :users, :only => :show
RUBY
end

gsub_file 'app/controllers/users_controller.rb', /def show/ do
<<-RUBY
before_filter :authenticate_user!

  def show
    @user = User.find(params[:id])
RUBY
end

if haml_flag
  run 'rm app/views/users/show.html.haml'
  # we have to use single-quote-style-heredoc to avoid interpolation
  create_file 'app/views/users/show.html.haml' do <<-'FILE'
%p
  User: #{@user.name}
  FILE
  end
else
  append_file 'app/views/users/show.html.erb' do <<-FILE
<p>User: <%= @user.name %></p>
  FILE
  end
end

if haml_flag
  create_file "app/views/devise/menu/_login_items.html.haml" do <<-'FILE'
- if user_signed_in?
  %li
    = link_to('Logout', destroy_user_session_path)
- else
  %li
    = link_to('Login', new_user_session_path)
  FILE
  end
else
  create_file "app/views/devise/menu/_login_items.html.erb" do <<-FILE
<% if user_signed_in? %>
  <li>
  <%= link_to('Logout', destroy_user_session_path) %>        
  </li>
<% else %>
  <li>
  <%= link_to('Login', new_user_session_path)  %>  
  </li>
<% end %>
  FILE
  end
end

if haml_flag
  create_file "app/views/devise/menu/_registration_items.html.haml" do <<-'FILE'
- if user_signed_in?
  %li
    = link_to('Edit account', edit_user_registration_path)
- else
  %li
    = link_to('Sign up', new_user_registration_path)
  FILE
  end
else
  create_file "app/views/devise/menu/_registration_items.html.erb" do <<-FILE
<% if user_signed_in? %>
  <li>
  <%= link_to('Edit account', edit_user_registration_path) %>
  </li>
<% else %>
  <li>
  <%= link_to('Sign up', new_user_registration_path)  %>
  </li>
<% end %>
  FILE
  end
end

if haml_flag
  run 'rm app/views/layouts/application.html.erb'
  create_file 'app/views/layouts/application.html.haml' do <<-FILE
!!!
%html
  %head
    %title Testapp
    = stylesheet_link_tag :all
    = javascript_include_tag :defaults
    = csrf_meta_tag
  %body
    %ul.hmenu
      = render 'devise/menu/registration_items'
      = render 'devise/menu/login_items'
    %p{:style => "color: green"}= notice
    %p{:style => "color: red"}= alert
    = yield
FILE
  end
else
  gsub_file 'app/views/layouts/application.html.erb', /<%= yield %>/ do
  <<-RUBY
<ul class="hmenu">
  <%= render 'devise/menu/registration_items' %>
  <%= render 'devise/menu/login_items' %>
</ul>
<p style="color: green"><%= notice %></p>
<p style="color: red"><%= alert %></p>
<%= yield %>
RUBY
  end
end

create_file 'public/stylesheets/application.css' do <<-FILE
ul.hmenu {
  list-style: none;	
  margin: 0 0 2em;
  padding: 0;
}

ul.hmenu li {
  display: inline;  
}
FILE
end

puts "checking everything into git..."
git :add => '.'
git :commit => "-m 'modified Rails app to use Mongoid and Devise'"

puts "Done setting up your Rails app with Mongoid and Devise."
