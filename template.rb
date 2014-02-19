# Gems
gem 'slim-rails'
gem 'figaro'

gem_group :development, :test do
  gem 'rspec-rails'
  gem 'factory_girl_rails'
end

# Run bundle
run 'bundle install --without production'

# RSpec
generate 'rspec:install'
remove_dir 'test'

# Figaro
generate 'figaro:install'

# Slim
environment "Slim::Engine.set_default_options pretty: true, sort_attrs: false\n", env: 'development'
environment "# Configure Slim", env: 'development'

# README
remove_file 'README.rdoc'
create_file 'README.md'

# Git
git :init
git add: '.'
git commit: %Q{ -m 'First Commit' }
