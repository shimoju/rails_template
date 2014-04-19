# Ask
# ==============================================================================
use = {}
use[:heroku] = yes?('Use Heroku?')
use[:puma] = yes?('Use Puma as the app server?')
use[:devise] = yes?('Use devise?')
use[:spring] = yes?('Use Spring preloader?')
use[:root] = yes?('Generate welcome#index as root path?')

# Git
# ==============================================================================
# .gitignore
append_to_file '.gitignore' do
%q{
.DS_Store
**.orig
/vendor/bundle
/spec/tmp
/coverage/
.env
.env.*
}
end

# Initial commit
git :init
git add: '.'
git commit: %Q{ -m 'Initial commit' }

# Gems
# ==============================================================================
# Use Rails Assets
add_source 'https://rails-assets.org'

# Specify Ruby version
prepend_to_file 'Gemfile', "ruby '#{RUBY_VERSION}'\n"

# Process manager
gem 'foreman'
# App server
gem 'puma' if use[:puma]

# Template engine
gem 'slim-rails'
# Authentication solution
gem 'devise' if use[:devise]

gem_group :production do
  gem 'pg' if use[:heroku]
  gem 'rails_12factor' if use[:heroku]
end

gem_group :test do
  # Acceptance test framework
  gem 'capybara'
  # A PhantomJS driver for Capybara
  gem 'poltergeist'
  # Database cleaner
  gem 'database_rewinder'
  # save_and_open_page
  gem 'launchy'
  # Generate fake data
  gem 'faker'
  # Code coverage analysis tool
  gem 'simplecov', '~> 0.7.1', require: false
end

gem_group :development, :test do
  # Testing framework
  gem 'rspec-rails', '~> 3.0.0.beta2'
  # Fixtures replacement
  gem 'factory_girl_rails'
  # Autoload .env
  gem 'dotenv-rails'
  # irb alternative
  gem 'pry-rails'
  gem 'pry-byebug'
  gem 'pry-coolline'
  gem 'pry-doc'
  gem 'pry-stack_explorer'
  # Format query log
  gem 'hirb-unicode'
  # Pretty prints
  gem 'awesome_print'
end

gem_group :development do
  # Better error page
  gem 'better_errors'
  gem 'binding_of_caller'
  # Turns off the asset pipeline log
  gem 'quiet_assets'
  # Spring
  gem 'spring-commands-rspec' if use[:spring]
  # Handle events on file system modifications
  gem 'guard'
  gem 'terminal-notifier-guard'
  gem 'guard-livereload', require: false
  gem 'guard-pow', require: false
  gem 'guard-rspec', require: false
  # Convert ERB to Slim
  gem 'html2slim', require: false
end

if use[:heroku]
  gsub_file 'Gemfile', "gem 'sqlite3'", "gem 'sqlite3', group: [:development, :test]"
end

# Run bundle
# ==============================================================================
run 'bundle install --without production'

# Config Application
# ==============================================================================
# Create files
# ------------------------------------------------------------------------------
# README
remove_file 'README.rdoc'
create_file 'README.md', "# #{app_name.classify}\n"
# Foreman
create_file 'Procfile', "web: bundle exec rails server -p $PORT\n"
create_file '.env' do
%q{# Add application configuration variables here, as shown below.
# Set the value generated by `bundle exec rake secret`
SECRET_KEY_BASE=your_secret_key
}
end

# application.rb
# ------------------------------------------------------------------------------
application do
 %q{# Config Generators
    config.generators do |g|
      g.test_framework :rspec,
        # controller_specs: false,
        # helper_specs: false,
        request_specs: false,
        routing_specs: false,
        view_specs: false
    end
}
end

# SSL
# ------------------------------------------------------------------------------
uncomment_lines 'config/environments/production.rb', 'config.force_ssl = true'

# Mailer
# ------------------------------------------------------------------------------
environment "config.action_mailer.default_url_options = { host: 'localhost:3000' }\n", env: 'development'

# Server
# ------------------------------------------------------------------------------
if use[:puma]
  remove_file 'Procfile'
  create_file 'Procfile', "web: bundle exec puma -C config/puma.rb\n"
  create_file 'config/puma.rb' do
%q{# https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server
workers Integer(ENV['PUMA_WORKERS'] || 3)
threads Integer(ENV['MIN_THREADS']  || 1), Integer(ENV['MAX_THREADS'] || 16)

preload_app!

rackup      DefaultRackup
port        ENV['PORT']     || 3000
environment ENV['RACK_ENV'] || 'development'

on_worker_boot do
  # worker specific setup
  ActiveSupport.on_load(:active_record) do
    ActiveRecord::Base.establish_connection
  end
end
}
  end
  create_file 'config/initializers/database_connection.rb' do
%q{# https://devcenter.heroku.com/articles/concurrency-and-database-connections
Rails.application.config.after_initialize do
  ActiveRecord::Base.connection_pool.disconnect!

  ActiveSupport.on_load(:active_record) do
    config = ActiveRecord::Base.configurations[Rails.env] ||
             Rails.application.config.database_configuration[Rails.env]
    config['reaping_frequency'] = ENV['DB_REAP_FREQ'] || 10 # seconds
    config['pool']              = ENV['DB_POOL']      || ENV['MAX_THREADS'] || 5
    ActiveRecord::Base.establish_connection(config)
  end
end
}
  end
  append_to_file '.env' do
%q{
# config/initializers/database_connection.rb
# DB_POOL=5
DB_REAP_FREQ=10

# config/puma.rb
MAX_THREADS=16
MIN_THREADS=1
PUMA_WORKERS=3
}
  end
end

# Config Gems
# ==============================================================================
# RSpec
# ------------------------------------------------------------------------------
generate 'rspec:install'
remove_dir 'test'
append_to_file '.rspec', "--format documentation\n"

# DatabaseRewinder
# ------------------------------------------------------------------------------
gsub_file 'spec/spec_helper.rb', "config.use_transactional_fixtures = true", "config.use_transactional_fixtures = false"
insert_into_file 'spec/spec_helper.rb', after: "RSpec.configure do |config|\n" do
%q{
  config.before :suite do
    DatabaseRewinder.clean_all
  end

  config.after :each do
    DatabaseRewinder.clean
  end

}
end

# factory_girl
# ------------------------------------------------------------------------------
insert_into_file 'spec/spec_helper.rb', after: "RSpec.configure do |config|\n" do
  "  config.include FactoryGirl::Syntax::Methods\n"
end
insert_into_file 'spec/spec_helper.rb', after: "config.before :suite do\n" do
  "    FactoryGirl.reload\n"
end

# SimpleCov
# ------------------------------------------------------------------------------
prepend_to_file 'spec/spec_helper.rb', "require 'simplecov'\n\n"
create_file '.simplecov', "SimpleCov.start 'rails'\n"

# Capybara
# ------------------------------------------------------------------------------
insert_into_file 'spec/spec_helper.rb', after: "require 'rspec/rails'\n" do
  "require 'capybara/rails'\nrequire 'capybara/rspec'\n"
end
# Poltergeist
insert_into_file 'spec/spec_helper.rb', after: "require 'capybara/rspec'\n" do
  "require 'capybara/poltergeist'\nCapybara.javascript_driver = :poltergeist\n"
end

# Guard
# ------------------------------------------------------------------------------
run 'bundle exec guard init'

# Slim
# ------------------------------------------------------------------------------
environment "# Configure Slim\n  Slim::Engine.set_default_options pretty: true, sort_attrs: false\n", env: 'development'
# Convert application.html.erb to Slim
run 'bundle exec erb2slim --delete app/views/layouts/application.html.erb app/views/layouts/application.html.slim'

# devise
# ------------------------------------------------------------------------------
if use[:devise]
  generate 'devise:install'
end

# Root path
# ==============================================================================
if use[:root]
  generate 'controller', 'welcome index'
  uncomment_lines 'config/routes.rb', "root 'welcome#index'"
  comment_lines 'config/routes.rb', "get 'welcome/index'"
end

# Environment variables
# ==============================================================================
# Copy sample file
run 'cp .env sample.env'
# secret_key_base
gsub_file '.env', "your_secret_key\n", `bundle exec rake secret`

# Database
# ==============================================================================
rake 'db:create'
rake 'db:migrate'

# Spring
# ==============================================================================
if use[:spring]
  run 'bundle exec spring binstub --all'
  gsub_file 'Guardfile', 'guard :rspec do', "guard :rspec, cmd: 'spring rspec' do"
end

# Git commit
# ==============================================================================
git add: '--all'
git commit: %Q{ -m 'Apply template' }
