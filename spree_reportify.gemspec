Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_reportify'
  s.version     = '3.0.7'
  s.summary     = 'Add gem summary here'
  s.description = 'Add (optional) gem description here'
  s.required_ruby_version = '>= 2.1.0'

  s.author    = 'You'
  s.email     = 'you@example.com'
  # s.homepage  = 'http://www.spreecommerce.com'

  s.files       = `git ls-files`.split("\n")
  s.test_files  = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_path = 'lib'
  s.requirements << 'none'

  spree_version = '~> 3.0.7'

  s.add_dependency 'spree_core', spree_version

  s.add_development_dependency 'capybara', '~> 2.4'
  s.add_development_dependency 'coffee-rails', '~> 4.0.0'
  s.add_development_dependency 'database_cleaner', '~> 1.2.0'
  s.add_development_dependency 'factory_girl', '~> 4.5'
  s.add_development_dependency 'ffaker', '~> 1.32.0'
  s.add_development_dependency 'mysql2', '~> 0.4.0'
  s.add_development_dependency 'pg', '~> 0.18.0'
  s.add_development_dependency 'rspec-rails',  '~> 3.1'
  s.add_development_dependency 'sass-rails', '~> 5.0.0'
  s.add_development_dependency 'chartkick', '~> 1.4.0'
  s.add_development_dependency 'selenium-webdriver', '~> 2.52.0'
  s.add_development_dependency 'simplecov', '~> 0.11.0'
  s.add_development_dependency 'sqlite3', '~> 1.3.0'
  s.add_development_dependency 'shoulda-matchers', '~> 2.6.2'
  s.add_development_dependency 'spree_backend', spree_version
  s.add_development_dependency 'spree_frontend', spree_version
  s.add_dependency 'sequel', '~> 4.32.0'
  s.add_dependency 'wicked_pdf', '~> 1.0.6'
  s.add_dependency 'wkhtmltopdf-binary', '~> 0.9.9.3'
end
