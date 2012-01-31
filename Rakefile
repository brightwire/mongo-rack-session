require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "mongo-rack-session"
  gem.version = '0.1.2'
  gem.homepage = "http://github.com/davidyang/mongo-rack-session"
  gem.license = "MIT"
  gem.summary = %Q{ one-line summary of your gem}
  gem.description = %Q{longer description of your gem}
  gem.email = "david.g.yang@gmail.com"
  gem.authors = ["David Yang"]
  
  gem.add_runtime_dependency 'mongo_mapper'
  gem.add_runtime_dependency 'uuid'
  gem.add_runtime_dependency 'rack'
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :default => :test

