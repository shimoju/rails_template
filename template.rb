# Ask
# ==============================================================================
use = {}
use[:heroku] = yes?('Use Heroku?')
use[:puma] = yes?('Use Puma as the app server?')
use[:figaro] = yes?('Use Figaro config manager?')

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
*.sassc
.sass-cache
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
# Config manager
gem 'figaro' if use[:figaro]

gem_group :production do
  gem 'pg' if use[:heroku]
  gem 'rails_12factor' if use[:heroku]
end

gem_group :test do
  # Acceptance test framework
  gem 'capybara'
end

gem_group :development, :test do
  # Testing framework
  gem 'rspec-rails', '~> 3.0.0.beta'
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
  # Handle events on file system modifications
  gem 'guard'
  gem 'terminal-notifier-guard'
  gem 'guard-livereload', require: false
  gem 'guard-pow', require: false
  gem 'guard-rspec', require: false
  # Better error page
  gem 'better_errors'
  gem 'binding_of_caller'
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
# application.rb
# ------------------------------------------------------------------------------
application do
 %q{# Config Generators
    config.generators do |g|
      g.test_framework :rspec,
        helper_specs: false,
        request_specs: false,
        routing_specs: false,
        view_specs: false
    end
}
end

# SSL
# ------------------------------------------------------------------------------
uncomment_lines 'config/environments/production.rb', 'config.force_ssl = true'

# Server
# ==============================================================================
# Foreman
# ------------------------------------------------------------------------------
create_file 'Procfile' do
  if use[:puma]
    "web: bundle exec puma -t ${PUMA_MIN_THREADS:-8}:${PUMA_MAX_THREADS:-12} -w ${PUMA_WORKERS:-2} -p $PORT -e ${RACK_ENV:-development}\n"
  else
    "web: bundle exec rails server -p $PORT\n"
  end
end

# Puma
# ------------------------------------------------------------------------------
if use[:puma]
  create_file 'config/initializers/database_connection.rb' do
%q{# https://devcenter.heroku.com/articles/concurrency-and-database-connections
Rails.application.config.after_initialize do
  ActiveRecord::Base.connection_pool.disconnect!

  ActiveSupport.on_load(:active_record) do
    config = Rails.application.config.database_configuration[Rails.env]
    config['reaping_frequency'] = ENV['DB_REAP_FREQ'] || 10 # seconds
    config['pool']              = ENV['DB_POOL']      || 5
    ActiveRecord::Base.establish_connection(config)
  end
end
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

# factory_girl
# ------------------------------------------------------------------------------
insert_into_file 'spec/spec_helper.rb', after: "RSpec.configure do |config|\n" do
  "  config.include FactoryGirl::Syntax::Methods\n\n"
end

# Guard
# ------------------------------------------------------------------------------
run 'bundle exec guard init'

# Slim
# ------------------------------------------------------------------------------
environment "Slim::Engine.set_default_options pretty: true, sort_attrs: false\n", env: 'development'
environment "# Configure Slim", env: 'development'
# Convert application.html.erb to Slim
run 'bundle exec erb2slim --delete app/views/layouts/application.html.erb app/views/layouts/application.html.slim'
# Fix doctype
gsub_file 'app/views/layouts/application.html.slim', /^doctype$/, 'doctype html'

# Figaro
# ------------------------------------------------------------------------------
if use[:figaro]
  generate 'figaro:install'
  # Copy sample file
  run 'cp config/application.yml config/application.sample.yml'
end

# README
# ==============================================================================
remove_file 'README.rdoc'
create_file 'README.md', "# #{app_name.classify}\n"

# Root path
# ==============================================================================
generate 'controller', 'welcome index'
uncomment_lines 'config/routes.rb', "root 'welcome#index'"
comment_lines 'config/routes.rb', "get 'welcome/index'"

# Database
# ==============================================================================
rake 'db:create'
rake 'db:migrate'

# Git commit
# ==============================================================================
git add: '--all'
git commit: %Q{ -m 'Apply template' }
