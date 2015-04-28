require 'pp'

# A generic Webmachine Resource that can be sub-classed by other resources
# of McFS REST API

module McFS; module Service

  class McFSResource < Webmachine::Resource
    
    def allowed_methods
      ['GET', 'POST']
    end
    
    def content_types_provided
      [["application/x-yaml", :yaml_response]]
    end
    
    # TODO: need to implement this properly
    def resource_exists?
      true
    end
    
    # Called for GET operation
    def yaml_response
      Log.info "REST API v1 - GET #{request.uri}"
      
      # method ::= action_get_<action>
      response_data = perform_action(:get)
      
      # If the function returned an integer, then its an HTTP response
      # code due to error condition.
      if response_data.is_a? Integer
        response_data
      else
        response_data.to_yaml
      end
      
    end # yaml_response
    
    # Called for POST operation
    def process_post
      Log.info "REST API v1 - POST #{request.uri}"
      
      response_data = perform_action(:post)
      
      # If the function returned an integer, then its an HTTP response
      # code due to error condition.
      if response_data.is_a? Integer
        response.code = response_data
      else
        pp response_data
        response.body = response_data.to_yaml
        pp response_data.to_yaml
      end
    end # process_post
    
    private
    
    def action
      @action ||= request.path_info[:action]
    end
    
    def request_data
      # All requests are to be transmitted in YAML format
      @request_data ||= YAML.load(request.body.to_s)
    end
    
    def perform_action(type, *args)
      
      # All responses will be sent in YAML format
      response.headers['Content-Type'] = 'application/x-yaml'
      
      # Set default status as success
      response.code = 200
      
      # method ::= action_<get|post>_<action>
      method = "action_#{type}_#{action}"
      
      # See if the method for the requested action exists. If not return
      # a 404 error.
      if respond_to? method
        send(method, *args)
      else
        404
      end
    end
    
  end #McFSResource
  
end; end
