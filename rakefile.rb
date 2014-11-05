#!/usr/bin/env rake
require 'rake/testtask'
require 'rdoc/task'

RDoc::Task.new do |rdoc|
  rdoc.rdoc_dir = "rdoc"
  rdoc.rdoc_files = ['lib/option_list.rb', 'license.txt']
  rdoc.options << '--visibility' << 'private'
end

Rake::TestTask.new do |t|
  t.test_files = ['tests/option_list_test.rb']
  t.verbose = false
end

task :reek do |t|
  `reek lib\\*.rb > reek.txt`
end
