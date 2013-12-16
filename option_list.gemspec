#Specify the building of the option_list gem.

Gem::Specification.new do |s|
  s.name = "option_list"
  s.summary = "A unified handler for flexible function option parameters."
  s.description = 'A unified handler for flexible function option parameters. '
  s.version = '1.1.0' 
  s.author = ["Peter Camilleri"]
  s.email = "peter.c.camilleri@gmail.com"
  s.homepage = "http://teuthida-technologies.com/"
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = '>=1.9.3'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'minitest'  
  s.files = ['lib/option_list.rb', 'tests/option_list_test.rb', 'rakefile.rb', 'license.txt']
  s.extra_rdoc_files = ['license.txt']
  s.test_files = ['tests/option_list_test.rb']
  s.license = 'MIT'
  s.has_rdoc = true
  s.require_path = 'lib'
end

