# Questions
# ========================================
use_heroku = yes?('Use Heroku?')
use_ssl = yes?('Use SSL in production?')
use_puma = yes?('Use Puma as the app server?')
use_figaro = yes?('Use Figaro config manager?')

# Gems
# ========================================
prepend_to_file 'Gemfile' do
  "ruby '#{RUBY_VERSION}'\n"
end

gem 'foreman'
gem 'puma' if use_puma

gem 'slim-rails'
gem 'figaro' if use_figaro

gem_group :production do
  gem 'rails_12factor' if use_heroku
end

gem_group :test do
end

gem_group :development, :test do
  gem 'rspec-rails', '~> 3.0.0.beta'
  gem 'factory_girl_rails'
end

gem_group :development do
  gem 'pry-rails'
  gem 'guard'
  gem 'terminal-notifier-guard'
  gem 'guard-livereload', require: false
  gem 'guard-pow', require: false
  gem 'guard-rspec', require: false
end

# Run bundle
# ========================================
run 'bundle install --without production'

# Config Application
# ========================================
# application.rb
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
if use_ssl
  uncomment_lines 'config/environments/production.rb', 'config.force_ssl = true'
end

# Server
# ========================================
# Foreman
create_file 'Procfile'
append_to_file 'Procfile' do
  if use_puma
    "web: bundle exec puma -t ${PUMA_MIN_THREADS:-8}:${PUMA_MAX_THREADS:-12} -w ${PUMA_WORKERS:-2} -p $PORT -e ${RACK_ENV:-development}\n"
  else
    "web: bundle exec rails server -p $PORT\n"
  end
end

# Config Gems
# ========================================
# RSpec
generate 'rspec:install'
remove_dir 'test'
append_to_file '.rspec' do
  "--format documentation\n"
end

# factory_girl
insert_into_file 'spec/spec_helper.rb', after: "RSpec.configure do |config|\n" do
  "  config.include FactoryGirl::Syntax::Methods\n\n"
end

# Guard
run 'bundle exec guard init'

# Slim
environment "Slim::Engine.set_default_options pretty: true, sort_attrs: false\n", env: 'development'
environment "# Configure Slim", env: 'development'

# Figaro
if use_figaro
  generate 'figaro:install'
  # Copy sample file
  run 'cp config/application.yml config/application.sample.yml'
end

# README
# ========================================
remove_file 'README.rdoc'
create_file 'README.md' do
  "# #{app_name.classify}\n"
end

# Git
# ========================================
git :init
git add: '.'
git commit: %Q{ -m 'Initial commit' }
