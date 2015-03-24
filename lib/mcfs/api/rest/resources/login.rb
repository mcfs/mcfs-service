
require 'rpam'
require 'securerandom'

module McFS
  module RESTResources
    # Generate a 256 bit access token
    AppToken ||= SecureRandom.urlsafe_base64(256/8)
    
    class LoginResource < Webmachine::Resource
      include Rpam
      
      def allowed_methods
        ['POST']
      end
      
      # FIXME: need to add input validations
      
      def process_post
        login_request = JSON.parse(request.body.to_s)
        
        username = login_request['username']
        password = login_request['password']
        
        auth_status = authpam(username, password)
        
        response_hash = {
          'status' => auth_status,
          'token' => auth_status ? McFS::RESTResources::AppToken : ''
        }
        
        response.headers['Content-Type'] = 'application/json'
        response.body = JSON.dump(response_hash)
      end
      
    end #LoginResource
  end # RESTResources
end # McFS
