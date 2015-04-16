
module McFS
  module RESTResources
    # Generate a 256 bit access token
    AppToken ||= SecureRandom.urlsafe_base64(256/8)
    
    # GET /accounts to retrieve the list of cloud storage
    # accounts configured
    class AccountsResource < Webmachine::Resource
      
      def allowed_methods
        ['GET', 'POST']
      end
      
      def content_types_provided
        [["application/x-yaml", :to_yaml]]
      end
      
      def resource_exists?
        true
      end
      
      def to_yaml
        $filesystem.accounts.to_yaml
      end
      
      def process_post
        puts request.body.to_s
        
        account_info = YAML.load(request.body.to_s)
        p account_info
        
        $filesystem.add_account(account_info)
        
        response.headers['Content-Type'] = 'application/x-yaml'
        response.body = '---'
      end
      
    end #LoginResource
  end # RESTResources
end # McFS
