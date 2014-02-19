gem_group :development, :test do
  gem 'rspec-rails'
  gem 'factory_girl_rails'
end

run 'bundle install --without production'

generate 'rspec:install'
remove_dir 'test'

remove_file 'README.rdoc'
create_file 'README.md'

git :init
git add: '.'
git commit: %Q{ -m 'First Commit' }
