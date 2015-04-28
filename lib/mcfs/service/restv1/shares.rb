
require_relative 'resource'

module McFS; module Service

  class SharesResource < McFSResource
    
    def action_get_list
      Log.info "List shares action invoked"
      
      # Collect all namespaces that are stores
      Namespace.collect { |uuid, ns| uuid if ns.is_a? Share }.compact
    end
    
    def action_post_add
      Log.info "Add share action invoked"
      
      404 # Unsupported for now
      
      # uuid     = request_data['uuid']
      # service  = request_data['service']
      # token    = request_data['token']
      #
      # if McFS::Service::Store.instantiate(service, uuid, token)
      #   "success"
      # else
      #   "failure"
      # end
      
    end # add_share
    
  end #SharesResource
  
end; end
