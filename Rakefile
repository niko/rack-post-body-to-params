require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "rack-post-body-to-params"
    gem.summary = %Q{A Rack middleware that parses the POST or PUT body for JSON or XML content to a Hash and puts it into the rack.request.form_hash. Most frameworks get the params hash from there. Uses ActiveSupport and the respective parsers for parsing. So you can set it up to use Nokogiri and YajL. Useful for example when writing JSON and XML API apps with Sinatra or Padrino.}
    # gem.description = %Q{}
    gem.email = "mail+git@niko-dittmann.com"
    gem.homepage = "http://github.com/niko/rack-post-body-to-params"
    gem.authors = ["Niko Dittmann"]
    
    gem.add_development_dependency "shoulda", ">= 0"
    gem.add_runtime_dependency "activesupport", ">= 2.3"
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "rack-post-body-to-params #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
