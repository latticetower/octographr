#require 'rubygems'
require 'rake'
require 'rake/testtask'

desc 'Default: run all tests.'
task :default => :test

desc "Test all classes."
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.test_files = Dir['spec/*_spec.rb']
  t.verbose = true
  t.warning = true if ENV['WARNINGS']
end
