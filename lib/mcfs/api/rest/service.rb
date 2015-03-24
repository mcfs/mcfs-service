
require 'json'

require 'reel'
require 'webmachine'

require_relative 'resources/login'

module McFS
  RESTService = Webmachine::Application.new do |app|
    app.routes do
      add ['login'], McFS::RESTResources::LoginResource
    end
      
    app.configure do |config|
     # config.port    = 0
     config.adapter = :Reel
    end
  end
end
