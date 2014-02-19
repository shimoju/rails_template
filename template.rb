remove_file 'README.rdoc'
create_file 'README.md'

git :init
git add: '.'
git commit: %Q{ -m 'First Commit' }
