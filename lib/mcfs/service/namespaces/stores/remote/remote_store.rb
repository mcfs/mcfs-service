
module McFS; module Service
  
  # Remote stores represent cloud storage services
  class RemoteStore < Store
    class MetaData
      attr_reader :name, :mtime
      
      # NOTE: name is basename (not path)
      def initialize(name, mtime)
        @name = name
        @mtime = mtime
      end
    end
    
    class DirMeta < MetaData
      attr_reader :contents
      
      def initialize(name, mtime)
        super
        @contents = []
      end
      
      def add_entry(meta)
        @contents << meta
      end
      
      def remove_entry(name)
        @contents.delete_if { |entry| entry.name == name }
      end
    end
    
    class FileMeta < MetaData
      attr_reader :size
      
      def initialize(name, size, mtime)
        super(name, mtime)
        @size = size
      end
    end
    
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
        
        meta[dir] = metadata(dir)
        
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
      dirpath = Pathname.new(dirpath).cleanpath.to_s
      dirmeta = @metadata ? @metadata[dirpath] : metadata(dirpath)
      dirmeta.contents.collect { |entry| entry.name }
    end
    
    private
    
    # Retrieve metadata of a directory
    def metadata(dirpath)
      throw UnimplementedFeature
    end
    
  end
end; end
