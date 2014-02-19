# Gems
gem_group :development, :test do
  gem 'rspec-rails'
  gem 'factory_girl_rails'
end

# Run bundle
run 'bundle install --without production'

# RSpec
generate 'rspec:install'
remove_dir 'test'

# README
remove_file 'README.rdoc'
create_file 'README.md'

# Git
git :init
git add: '.'
git commit: %Q{ -m 'First Commit' }
