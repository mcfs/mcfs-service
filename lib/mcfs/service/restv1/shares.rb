
module McFS; module Service

  class SharesResource < Webmachine::Resource
    
    def allowed_methods
      ['GET']
    end
    
    def content_types_provided
      [["application/x-yaml", :yaml_response]]
    end
    
    def resource_exists?
      true
    end
    
    def yaml_response
      {}.to_yaml
    end
    
    # def process_post
    #   puts request.body.to_s
    #   response.headers['Content-Type'] = 'application/x-yaml'
    #   response.body = '---'
    # end
    
  end #SharesResource
  
end; end
