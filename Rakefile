begin
  require 'bundler/gem_tasks'
rescue LoadError
  warn 'You must `gem install bundler` and `bundle install` to run rake tasks'
  exit(1)
end

require 'rake/clean'
require 'rake/testtask'

spec = Gem::Specification.load(FileList['*.gemspec'].first)

task :default => [:test, :install]

Rake::TestTask.new do |t|
  t.test_files = spec.test_files
end