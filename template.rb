# Questions
use_ssl = yes?('Use SSL in production?')

# Gems
gem 'slim-rails'
gem 'figaro'

gem_group :development, :test do
  gem 'rspec-rails', '~> 3.0.0.beta'
  gem 'factory_girl_rails'
end

gem_group :development do
  gem 'pry-rails'
  gem 'guard'
  gem 'terminal-notifier-guard'
end

# Run bundle
run 'bundle install --without production'

# RSpec
generate 'rspec:install'
remove_dir 'test'
append_to_file '.rspec' do
  "--format documentation\n"
end

# Figaro
generate 'figaro:install'
## Copy sample file
run 'cp config/application.yml config/application.sample.yml'

# Guard
run 'bundle exec guard init'

# Slim
environment "Slim::Engine.set_default_options pretty: true, sort_attrs: false\n", env: 'development'
environment "# Configure Slim", env: 'development'

# SSL
if use_ssl
  uncomment_lines 'config/environments/production.rb', 'config.force_ssl = true'
end

# README
remove_file 'README.rdoc'
create_file 'README.md'

# Git
git :init
git add: '.'
git commit: %Q{ -m 'First Commit' }
