
# APIs:
#  GET  /stores/list - list all store names
#  POST /stores/add  - add a new store (currently supports Dropbox)

module McFS; module Service

  class StoresResource < Webmachine::Resource
    
    def allowed_methods
      ['GET', 'POST']
    end
    
    def content_types_provided
      [["application/x-yaml", :yaml_response]]
    end
    
    def resource_exists?
      true
    end
    
    def yaml_response
      puts "pass 1"
      case action
      when 'list'
        list_stores
      else
        404
      end
    end # yaml_response
    
    def process_post
      req_data = YAML.load(request.body.to_s)
      
      response.headers['Content-Type'] = 'application/x-yaml'
      response.body = '---'
      response.code = 200
      
      case action
      when 'add'
        add_store(req_data)
      else
        response.code = 404
      end
      
    end # process_post
    
    private
    
    def action
      @action ||= request.path_info[:action]
    end
    
    # TODO: It's probably better to separate actions to into its own classes
    
    def list_stores
      stores = McFS::Service::Store.collect { |uuid, store| uuid }
      response.body = stores.to_yaml
    end
    
    # FIXME: need to support other kinds of stores
    def add_store(req)
      uuid     = req['uuid']
      service  = req['service']
      token    = req['token']
      
      if McFS::Service::Store.add(uuid, service, token)
        response.body = "success".to_yaml
      else
        response.body = "failed".to_yaml
      end
    end # add_store
    
  end #StoresResource
  
end; end
