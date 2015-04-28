
require_relative 'resource'

# FileSystems will be supported at a later stage.

# APIs:

module McFS; module Service

  class FileSystemsResource < McFSResource
    
    def action_get_list
      Log.info "List filesystems action invoked"
      
      # Collect all namespaces that are stores
      Namespace.collect { |uuid, ns| uuid if ns.is_a? FileSystem }.compact
    end
    
    # POST /filesystems/add
    #
    def action_post_add
      Log.info "Add filesystem action invoked"
      
      uuid     = request_data['uuid']
      
      if McFS::Service::FileSystem.instantiate(uuid)
        "success"
      else
        "failure"
      end
      
    end # action_post_add
    
    def action_post_mountns
      Log.info "Mounting namespace under filesystem"
      
      fs_uuid = request_data['filesystem']
      ns_uuid = request_data['namespace']
      
      uuid, fs_obj = Namespace.find { |uuid, ns| uuid == fs_uuid }
      uuid, ns_obj = Namespace.find { |uuid, ns| uuid == ns_uuid }
      
      if fs_obj and ns_obj
        # Mount the namespace with its name as mount point
        # FIXME: check for success/failure
        if fs_obj.mount(ns_obj, ns_uuid)
          "success"
        else
          "failure"
        end
      else
        # FIXME: return proper error
        404
      end
      
    end # action_post_mountns
    
    def action_post_browse
      Log.info "Browsing filesystem directory"
      
      fs_uuid = request_data['filesystem']
      dirpath = request_data['directory']
      
      uuid, fs_obj = Namespace.find { |uuid, ns| uuid == fs_uuid }
      
      if fs_obj
        fs_obj.list dirpath
      else
        # FIXME: return proper error
        404
      end
      
    end # action_post_browse
    
    def action_post_metadata
      Log.info "Retrieving metadata of a directory entry"
      
      fs_uuid = request_data['filesystem']
      fs_path = request_data['path']
      
      uuid, fs_obj = Namespace.find { |uuid, ns| uuid == fs_uuid }
      
      if fs_obj
        if meta = fs_obj.metadata(fs_path)
          meta.to_hash
        else
          nil
        end
      else
        # FIXME: return proper error
        404
      end
      
    end # action_post_metadata
    
    def action_post_readfile
      Log.info "Reading contents of file"
      
      fs_uuid = request_data['filesystem']
      fs_path = request_data['path']
      
      uuid, fs_obj = Namespace.find { |uuid, ns| uuid == fs_uuid }
      
      if fs_obj
        fs_obj.readfile(fs_path)
      else
        # FIXME: return proper error
        404
      end
      
    end # readfile
    
    def action_post_writefile
      Log.info "Write contents of file"
      
      fs_uuid = request_data['filesystem']
      fs_path = request_data['path']
      data = request_data['data']
      
      uuid, fs_obj = Namespace.find { |uuid, ns| uuid == fs_uuid }
      
      if fs_obj and fs_obj.writefile(fs_path, data)
        nil
      else
        # FIXME: return proper error
        404
      end
      
    end # writefile
    
    def action_post_mkdir
      Log.info "Make new directory"
      
      fs_uuid = request_data['filesystem']
      fs_path = request_data['path']
      
      uuid, fs_obj = Namespace.find { |uuid, ns| uuid == fs_uuid }
      
      if fs_obj and fs_obj.mkdir(fs_path)
        nil
      else
        # FIXME: return proper error
        404
      end
      
    end # mkdir
    
    def action_post_delete
      Log.info "Delete a path"
      
      fs_uuid = request_data['filesystem']
      fs_path = request_data['path']
      
      uuid, fs_obj = Namespace.find { |uuid, ns| uuid == fs_uuid }
      
      if fs_obj and fs_obj.delete(fs_path)
        nil
      else
        # FIXME: return proper error
        404
      end
      
    end # delete
    
  end #FileSytemsResource
  
end; end
