
# FileSystems will be supported at a later stage.

# APIs:

module McFS; module Service

  class FileSystemsResource < Webmachine::Resource
    
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
      case action
      when 'list'
        # McFS::Service::Namespace.list.to_yaml
      else
        404
      end
    end # yaml_response
    
    def process_post
      
      nsreq = YAML.load(request.body.to_s)
      
      response.headers['Content-Type'] = 'application/x-yaml'
      response.body = '---'
      response.code = 200
      
      case action
      when 'listfiles'
        listfiles_action(nsreq)
      when 'add'
        # TODO: implement this action
        response.code = 404
      else
        response.code = 404
      end
      
    end # process_post
    
    private
    
    def action
      @action ||= request.path_info[:action]
    end
    
    def listfiles_action(nsreq)
      namespace = nsreq['namespace']
      dirpath   = nsreq['dirpath']
      
      rsp = McFS::Service::Namespace.listfiles(namespace, dirpath).to_yaml
      p rsp
      response.body = rsp
    end
    
  end #NamespacesResource
  
end; end
