
require_relative 'resource'

module McFS; module Service

  class SharesResource < McFSResource
    
    def action_get_list
      Log.info "List shares action invoked"
      
      # Collect all namespaces that are stores
      Namespace.collect { |nsid, ns| nsid if ns.is_a? McFSShare }.compact
    end
    
    def action_post_add
      Log.info "Add share action invoked"
      
      nsid = request_data['uuid']
      store_nsids = request_data['stores']
      stores = []
      
      store_nsids.each do |store_nsid|
        store_nsid, store = Namespace.find {|nsid, ns| nsid == store_nsid }
        
        if store
          stores << store
        else
          return 'failure'
          throw something
        end
      end
      
      # Just create the object and it will added to global namespace list
      McFS::Service::McFSShare.new(nsid, stores)
      
      McFS::Service::Config.add(request.disp_path, request_data)
      
      return 'success'
      
    end # add_share
    
  end #SharesResource
  
end; end
