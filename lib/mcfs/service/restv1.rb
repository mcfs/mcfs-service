
require 'reel'
require 'webmachine'

#require_relative 'restv1/namespaces'
require_relative 'restv1/stores'
#require_relative 'restv1/shares'

module McFS; module Service
  
  class RESTv1
    
    def initialize(ip, port)
      @webmachine = Webmachine::Application.new
      
      @webmachine.routes do
        # add ['api', 'v1', 'namespaces', :action], McFS::Service::NamespacesResource
        add ['api', 'v1', 'stores', :action], McFS::Service::StoresResource
        # add ['api', 'v1', 'shares', :action], McFS::Service::SharesResource
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
