# execute this file to test for xml/yaml code execution

require 'yaml'
gem 'activesupport', '=3.1'
require 'active_support'
require 'active_support/core_ext/hash'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

puts "AS Version: #{ActiveSupport::VERSION::STRING}"

require 'rack/post-body-to-params'
Rack::PostBodyToParams.new :app