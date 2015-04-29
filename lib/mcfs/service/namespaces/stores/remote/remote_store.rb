
module McFS; module Service
  
  # Remote stores represent cloud storage services
  class RemoteStore < Store
    
    # Remote stores need to implement some kind of mechanism for
    # automatic metadata caching
    
    def initialize(uuid)
      super
      
      # Fetch the complete metadata in the background. @metadata
      # will be nil until the whole metadata is fetched.
      Thread.new do
        @metadata = generate_metadata
      end
    end
    
    # Retrieve the complete metadata hash table
    def generate_metadata
      meta = {}
      dirs = ['/']
      
      while dir = dirs.pop
        Log.info "Fetching DirMeta for #{dir}"
        
        meta[dir] = dirmeta(dir)
        
        # Add sub-directories into dirs[]
        meta[dir].contents.each do |entry|
          if entry.is_a? DirMeta
            dirs << Pathname.new(dir + '/' + entry.name).cleanpath.to_s
          end
        end
      end
      
      meta
      
    end # generate_metadata
    
    def list(dirpath)
      Log.info "RemoteStore list contents of #{dirpath}"
      
      path = Pathname.new(dirpath).cleanpath.to_s
      meta = @metadata ? @metadata[dirpath] : dirmeta(dirpath)
      meta.contents.collect { |entry| entry.name }
    end
    
    def metadata(path)
      Log.info "RemoteStore metadata for #{path}"
      
      # For now we need metadata to be already cached
      unless @metadata
        throw UnimplementedFeature
      end

      if path == '/'
        @metadata[path]
      else
        filename = File.basename(path)
        parent_dir = File.dirname(path)
        
        if parent_meta = @metadata[parent_dir]
          parent_meta.contents.find { |entry| entry.name == filename }
        else
          nil
        end
        
      end
    end # metadata
    
    def update_metadata(path, meta)
      Log.info "RemoteStore updating metadata for #{path}"
      
      pp meta
      
      # NOTE: meta is expected to be never of the root directory
      
      parentdir = File.dirname(path)
      
      if parent = @metadata[parentdir]
        parent.remove_entry meta.name
        
        if meta.deleted?
          @metadata.delete(path) if meta.is_a? DirMeta
        else
          parent.add_entry meta
          @metadata[path] = meta if meta.is_a? DirMeta
        end
        
      else
        throw something
      end
      
      meta
      
    end # update_metadata
    
    private
    
    # Retrieve metadata of a directory
    def dirmeta(dirpath)
      throw UnimplementedFeature
    end
    
  end
end; end
