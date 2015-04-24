
require_relative 'resource'

# APIs:
#  GET  /stores/list - list all store names
#  POST /stores/add  - add a new store (currently supports Dropbox)

module McFS; module Service

  class StoresResource < McFSResource
    
    def action_get_list
      Log.info "List stores action invoked"
      
      # Collect all namespaces that are stores
      Namespace.collect { |uuid, ns| uuid if ns.is_a? Store }.compact
    end
    
    def action_post_add(request_data)
      Log.info "Add store action invoked"
      
      uuid     = request_data['uuid']
      service  = request_data['service']
      token    = request_data['token']
      
      if McFS::Service::Store.instantiate(service, uuid, token)
        "success"
      else
        "failure"
      end
      
    end # add_store
    
  end #StoresResource
  
end; end
