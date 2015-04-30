
require 'reel'
require 'webmachine'

require_relative 'restv1/filesystems'
require_relative 'restv1/stores'
require_relative 'restv1/shares'
require_relative 'restv1/config'

module McFS; module Service
  
  class RESTv1
    
    def initialize(ip, port)
      @webmachine = Webmachine::Application.new
      
      @webmachine.routes do
        add ['api', 'v1', 'filesystems', :action], McFS::Service::FileSystemsResource
        add ['api', 'v1', 'stores', :action], McFS::Service::StoresResource
        add ['api', 'v1', 'shares', :action], McFS::Service::SharesResource
        add ['api', 'v1', 'config', :action], McFS::Service::ConfigResource
      end
      
      @webmachine.configure do |config|
        config.ip      = ip
        config.port    = port
        config.adapter = :Reel
        config.adapter_options = { Logger: McFS::Service::Log }
      end
      
    end # initialize
    
    def run
      @webmachine.run
    end # run
    
  end # RESTv1

end ; end
