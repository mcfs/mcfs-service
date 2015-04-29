
require_relative 'resource'

# FileSystems will be supported at a later stage.

# APIs:

module McFS; module Service

  class FileSystemsResource < McFSResource
    
    def action_get_list
      Log.info "List filesystems action invoked"
      
      # Collect all namespaces that are stores
      Namespace.collect { |nsid, ns| nsid if ns.is_a? FileSystem }.compact
    end
    
    # POST /filesystems/add
    #
    def action_post_add
      Log.info "Add filesystem action invoked"
      
      nsid     = request_data['uuid']
      
      if McFS::Service::FileSystem.instantiate(nsid)
        "success"
      else
        "failure"
      end
      
    end # action_post_add
    
    def action_post_mountns
      Log.info "Mounting namespace under filesystem"
      
      fs_nsid = request_data['filesystem']
      ns_nsid = request_data['namespace']
      
      nsid, fs_obj = Namespace.find { |nsid, ns| nsid == fs_nsid }
      nsid, ns_obj = Namespace.find { |nsid, ns| nsid == ns_nsid }
      
      if fs_obj and ns_obj
        # Mount the namespace with its name as mount point
        # FIXME: check for success/failure
        if fs_obj.mount(ns_obj, ns_nsid)
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
      
      fs_nsid = request_data['filesystem']
      dirpath = request_data['directory']
      
      nsid, fs_obj = Namespace.find { |nsid, ns| nsid == fs_nsid }
      
      if fs_obj
        fs_obj.list dirpath
      else
        # FIXME: return proper error
        404
      end
      
    end # action_post_browse
    
    def action_post_metadata
      Log.info "Retrieving metadata of a directory entry"
      
      uuid, store = Namespace.find {|uuid,s| s.is_a? RemoteStore }
      
      fs_nsid = request_data['filesystem']
      fs_path = request_data['path']
      
      nsid, fs_obj = Namespace.find { |nsid, ns| nsid == fs_nsid }
      
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
      
      fs_nsid = request_data['filesystem']
      fs_path = request_data['path']
      
      nsid, fs_obj = Namespace.find { |nsid, ns| nsid == fs_nsid }
      
      if fs_obj
        fs_obj.readfile(fs_path)
      else
        # FIXME: return proper error
        404
      end
      
    end # readfile
    
    def action_post_writefile
      Log.info "Write contents of file"
      
      fs_nsid = request_data['filesystem']
      fs_path = request_data['path']
      data = request_data['data']
      
      nsid, fs_obj = Namespace.find { |nsid, ns| nsid == fs_nsid }
      
      if fs_obj and fs_obj.writefile(fs_path, data)
        nil
      else
        # FIXME: return proper error
        404
      end
      
    end # writefile
    
    def action_post_mkdir
      Log.info "Make new directory"
      
      fs_nsid = request_data['filesystem']
      fs_path = request_data['path']
      
      nsid, fs_obj = Namespace.find { |nsid, ns| nsid == fs_nsid }
      
      if fs_obj and fs_obj.mkdir(fs_path)
        nil
      else
        # FIXME: return proper error
        404
      end
      
    end # mkdir
    
    def action_post_delete
      Log.info "Delete a path"
      
      fs_nsid = request_data['filesystem']
      fs_path = request_data['path']
      
      nsid, fs_obj = Namespace.find { |nsid, ns| nsid == fs_nsid }
      
      if fs_obj and fs_obj.delete(fs_path)
        nil
      else
        # FIXME: return proper error
        404
      end
      
    end # delete
    
  end #FileSytemsResource
  
end; end
