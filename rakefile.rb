#!/usr/bin/env rake
# coding: utf-8

require 'rake/testtask'
require 'rdoc/task'
require "bundler/gem_tasks"

RDoc::Task.new do |rdoc|
  rdoc.rdoc_dir = "rdoc"

  #List out all the files to be documented.
  rdoc.rdoc_files.include("lib/**/*.rb", "license.txt", "README.md")

  rdoc.options << '--visibility' << 'private'
end

Rake::TestTask.new do |t|
  t.test_files = ['tests/option_list_test.rb']
  t.verbose = false
end

desc "Run a scan for smelly code!"
task :reek do |t|
  `reek lib\\*.rb > reek.txt`
end

desc "What version of option_list is this?"
task :vers do |t|
  puts
  puts "option_list version = #{OptionList::VERSION}"
end