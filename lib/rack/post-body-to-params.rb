# gem 'activesupport', '=2.3.8'
# gem 'activesupport', '=3.0.0.beta4' # for tests
require 'active_support'
require 'active_support/core_ext/hash'

module Rack

  # A Rack middleware for parsing POST/PUT body data when
  # Content-Type is <tt>application/json</tt> or <tt>application/xml</tt>.
  #
  # Uses ActiveSupport::JSON.decode for json and ActiveSupports enhanced Hash
  # #from_xml for xml. Be shure to have ActiveSupport required beforehand.
  #
  # Configure parsers for ActiveSupport (you should do this perhaps anyway):
  #
  #   ActiveSupport::JSON.backend = 'Yajl'
  #   ActiveSupport::XmlMini.backend = 'Nokogiri'
  #
  # concerning Yajl: https://rails.lighthouseapp.com/projects/8994/tickets/4897-yajl-backend-discovery-fails-in-activesupportjson
  #
  # Note that all parsing errors will be rescued and returned back to the client.
  #
  # Most parts blantly stolen from http://github.com/rack/rack-contrib.
  #
  class PostBodyToParams

    # Constants
    #
    CONTENT_TYPE = 'CONTENT_TYPE'.freeze
    POST_BODY = 'rack.input'.freeze
    FORM_INPUT = 'rack.request.form_input'.freeze
    FORM_HASH = 'rack.request.form_hash'.freeze

    # Supported Content-Types
    #
    APPLICATION_JSON = 'application/json'.freeze
    APPLICATION_XML  = 'application/xml'.freeze

    attr_reader :parsers, :error_responses

    # Override the parsers and the error responses as needed:
    #
    #   use Rack::PostBodyContentTypeParser,
    #       :content_types => ['application/xml'],
    #       :parsers => {
    #         'application/xml' => Proc.new{|a| my_own_xml_parser a },
    #         'application/foo' => Proc.new{|a| my_foo_parser a }
    #       }
    #
    def initialize(app, config={})
      @content_types = config.delete(:content_types) || [APPLICATION_JSON, APPLICATION_XML]
      
      @parsers = {
        APPLICATION_JSON => Proc.new{ |post_body| parse_as_json post_body },
        APPLICATION_XML =>  Proc.new{ |post_body| parse_as_xml  post_body }
      }
      @parsers.update(config[:parsers]) if config[:parsers]
      
      @error_responses = {
        APPLICATION_JSON => Proc.new{ |error| json_error_response error },
        APPLICATION_XML =>  Proc.new{ |error| xml_error_response  error }
      }
      @error_responses.update(config[:error_responses]) if config[:error_responses]
      
      @app = app
    end

    def parse_as_xml(xml_data)
      Hash.from_xml xml_data
    end
    def parse_as_json(json_data)
      ActiveSupport::JSON.decode json_data
    end

    def json_error_response(error)
      [ 400, {'Content-Type' => APPLICATION_JSON}, [ {"json-syntax-error" => error.to_s}.to_json ] ]
    end
    def xml_error_response(error)
      [ 400, {'Content-Type' => APPLICATION_XML}, [ {"xml-syntax-error" => error.to_s}.to_xml(:root => :errors) ] ]
    end

    def call(env)
      content_type = env[CONTENT_TYPE] && env[CONTENT_TYPE].split(';').first
      
      if content_type && @content_types.include?(content_type)
        post_body = env[POST_BODY].read
        
        unless post_body.blank?
          begin
            new_form_hash = parsers[content_type].call post_body
          rescue Exception => error
            logger.warn "#{self.class} #{content_type} parsing error: #{error.to_s}" if respond_to? :logger
            return error_responses[content_type].call error
          end
          env.update(FORM_HASH => new_form_hash, FORM_INPUT => env[POST_BODY])
        end
        
      end
      
      @app.call(env)
    end

  end
end
