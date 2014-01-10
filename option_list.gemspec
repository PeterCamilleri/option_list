#Specify the building of the option_list gem.

Gem::Specification.new do |s|
  s.name = "option_list"
  s.summary = "Flexible, Easy Function Parameters with Validation."
  s.description = 'Flexible, Easy Function Parameters with Validation. '
  s.version = '1.1.1' 
  s.author = ["Peter Camilleri"]
  s.email = "peter.c.camilleri@gmail.com"
  s.homepage = "http://teuthida-technologies.com/"
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = '>=1.9.3'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'reek'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'awesome_print'
  s.files = ['lib/option_list.rb', 'tests/option_list_test.rb', 'rakefile.rb', 'license.txt', 'README', 'reek.txt']
  s.extra_rdoc_files = ['license.txt']
  s.test_files = ['tests/option_list_test.rb']
  s.license = 'MIT'
  s.has_rdoc = true
  s.require_path = 'lib'
end

