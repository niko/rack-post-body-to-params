require 'helper'
# ActiveSupport::JSON.backend = 'JSONGem'
ActiveSupport::JSON.backend = 'Yajl'
ActiveSupport::XmlMini.backend = 'Nokogiri'

class TestApp
  def call(env)
    return env
  end
end

class TestPostBodyToParams < Test::Unit::TestCase
  
  context "A new app" do
    context "without further configuration" do
      setup do
        @test_app = TestApp.new
        @app = Rack::PostBodyToParams.new @test_app
      end
      should "have the default content_types" do
        assert_equal ['application/json','application/xml'], @app.instance_variable_get('@content_types').sort
      end
      should "have the default parsers" do
        assert @app.parsers.keys.include? 'application/json'
        assert @app.parsers.keys.include? 'application/xml'
        assert @app.parsers['application/json'].is_a? Proc
        assert @app.parsers['application/xml'].is_a? Proc
      end
      should "have the default error responses" do
        assert @app.error_responses.keys.include? 'application/json'
        assert @app.error_responses.keys.include? 'application/xml'
        assert @app.error_responses['application/json'].is_a? Proc
        assert @app.error_responses['application/xml'].is_a? Proc
      end
    end

    context "with further configuration" do
      should "have different content_types" do
        app = Rack::PostBodyToParams.new @test_app, :content_types => [:fu]
        assert_equal [:fu], app.instance_variable_get('@content_types')
      end
      should "have different parsers" do
        app = Rack::PostBodyToParams.new @test_app, :parsers => {'application/json' => :bar}
        assert_equal :bar, app.parsers['application/json']
      end
      should "have different error responses" do
        app = Rack::PostBodyToParams.new @test_app, :error_responses => {'application/json' => :baz}
        assert_equal :baz, app.error_responses['application/json']
      end
    end
  end
  
  context "the parsers" do
    setup do
      @test_app = TestApp.new
      @app = Rack::PostBodyToParams.new @test_app
    end
    should "return the error as xml" do
      error = 'some error occured'
      response = [400, {"Content-Type"=>"application/xml"}, ["<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<errors>\n  <xml-syntax-error>some error occured</xml-syntax-error>\n</errors>\n"]]
      assert_equal response, @app.xml_error_response(error)
    end
    should "return the error as json" do
      error = 'some error occured'
      response = [400, {"Content-Type"=>"application/json"}, ["{\"json-syntax-error\":\"some error occured\"}"]]
      assert_equal response, @app.json_error_response(error)
    end
  end
  
  context "the error responses" do
    setup do
    end
  end
  
  context "the app itself" do
    setup do
      @test_app = TestApp.new
      @app = Rack::PostBodyToParams.new @test_app
    end
    should "put json string data into the form_hash" do
      env = {
        'CONTENT_TYPE' => 'application/json',
        'rack.input' => StringIO.new('{"bla":"blub"}')
      }
      new_env = @app.call(env)
      assert_equal({"bla"=>"blub"}, new_env['rack.request.form_hash'])
      assert_equal env['rack.input'], new_env['rack.request.form_input']
    end
    should "work with charset specification, too" do
      env = {
        'CONTENT_TYPE' => 'application/json; charset=ISO-8859-1',
        'rack.input' => StringIO.new('{"bla":"blub"}')
      }
      new_env = @app.call(env)
      assert_equal({"bla"=>"blub"}, new_env['rack.request.form_hash'])
      assert_equal env['rack.input'], new_env['rack.request.form_input']
    end
    should "work without any content type" do
      env = {
        'rack.input' => StringIO.new('{"bla":"blub"}')
      }
      new_env = @app.call(env) # doesnt raise
    end
    should "return 400 and the error message on faulty json" do
      env = {
        'CONTENT_TYPE' => 'application/json',
        'rack.input' => StringIO.new('{"bla":"blub"}}')
      }
      code, header, body = @app.call(env)
      assert_equal 400, code
      assert_equal 'application/json', header['Content-Type']
      assert_match /json-syntax-error/, body.first
    end
    should "return 400 and the error message on faulty xml" do
      env = {
        'CONTENT_TYPE' => 'application/xml',
        'rack.input' => StringIO.new("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<track>\n<title>\nfo\n</title>")
      }
      code, header, body = @app.call(env)
      assert_equal 400, code
      assert_equal 'application/xml', header['Content-Type']
      assert_match /xml-syntax-error/, body.first
    end
    should "check at init to make sure yaml parsing will not happen" do
      test_app = TestApp.new
      if Hash.const_defined?("DisallowedType")
        Hash::DISALLOWED_XML_TYPES.delete("yaml")
        begin
          assert_raise Rack::PostBodyToParams::YamlNotSafe do
            Rack::PostBodyToParams.new test_app
          end
        ensure
          Hash::DISALLOWED_XML_TYPES << "yaml"
        end
      elsif Kernel.const_defined?("ActiveSupport") &&
          ActiveSupport.const_defined?("XMLConverter") &&
          ActiveSupport::XMLConverter.const_defined?("DisallowedType")
        ActiveSupport::XMLConverter::DISALLOWED_TYPES.delete("yaml")
        begin
          assert_raise Rack::PostBodyToParams::YamlNotSafe do
            Rack::PostBodyToParams.new test_app
          end
        ensure
          ActiveSupport::XMLConverter::DISALLOWED_TYPES << "yaml"
        end
      end
    end
      
    should "process multipart requests that contain a root part of proper type" do
      body = <<-EOS
--MultipartBoundary\r
Content-Disposition: form-data; name="json"\r
Content-Type: "application/json; charset=UTF-8"\r
\r
{"bla":"blub"}\r
\r
--MultipartBoundary\r
Content-Disposition: form-data; name="multipart_file"; filename="multipart_file"\r
Content-Length: 22\r
Content-Type: text/plain\r
Content-Transfer-Encoding: binary\r
\r
file content goes here\r
--MultipartBoundary--\r
      EOS

      env = {
        'CONTENT_TYPE' => 'multipart/mixed; boundary="MultipartBoundary"; type="application/json"; start="json"',
        'rack.input' => StringIO.new(body)
      }
      new_env = @app.call(env)
      assert_equal(["bla", "multipart_file"].sort, new_env['rack.request.form_hash'].keys.sort)
      assert_equal(new_env['rack.request.form_hash']["bla"], "blub")
      file = new_env['rack.request.form_hash']["multipart_file"]
      assert file && file.is_a?(Hash)
      assert file.key?(:filename)
      assert file.key?(:tempfile)
    end

  end
  
end
