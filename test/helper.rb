require 'rubygems'
require 'test/unit'
require 'shoulda'

require 'safe_yaml'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rack/post-body-to-params'
