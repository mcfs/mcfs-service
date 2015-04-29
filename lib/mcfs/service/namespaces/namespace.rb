
# Namespaces provide a mechanism to combine one of more
# namespaces without name collisions

module McFS; module Service
  
  # Define all class variables and methods
  class Namespace
    include Celluloid
    
    # Repository that maps all namespaces from their nsid
    # nsid(String) => Namespace
    @@repo = {}
    
    # TODO: probably need to use Forwardable to delegate to @@repo
    
    def self.has_nsid?(nsid)
      @@repo.has_key? nsid
    end
    
    def self.add_nsid(nsid, nsobj)
      # FIXME: implement the following exception
      # throw <exception> if @@repo.has_key? nsid
      @@repo[nsid] = nsobj
    end
    
    def self.find(&block)
      @@repo.find &block
    end
    
    def self.each(&block)
      @@repo.each &block
    end
    
    def self.collect(&block)
      @@repo.collect &block
    end
    
  end # Namespace<static>
  
  # Define all instance variables and methods
  class Namespace
    
    class MetaData
      attr_reader :name, :mtime
      attr_accessor :deleted
      alias_method :deleted?, :deleted
      
      # NOTE: name is basename (not path)
      def initialize(name, mtime)
        @name = name
        @mtime = mtime
        @deleted = false
      end
      
      def to_hash
        {
          'name' => @name,
          'mtime' => @mtime
        }
      end
    end # MetaData
    
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
      
      def to_hash
        super.merge({ 'type' => :directory })
      end
    end # DirMeta
    
    class FileMeta < MetaData
      attr_reader :size
      
      def initialize(name, size, mtime)
        super(name, mtime)
        @size = size
      end
      
      def to_hash
        super.merge({ 'size' => size, 'type' => :file })
      end
    end # FileMeta
    
    # Every namespace has a unique identifier
    attr_reader :nsid, :names
    
    # Not sure what arguments are needed for intialization
    def initialize(nsid)
      # FIXME: add checks for validating the format of nsid string
      @nsid = nsid
      
      # Maps from a name to its namespace handler
      # name(String) => Namespace
      @names = {}
      
      self.class.add_nsid(nsid, self)
    end
    
    # Return [base, rest]
    def split_path(path)
      base, *rest = path.scan(/[^\/]+/)
      [ base, '/' + File.join(rest) ]
    end
    
    # Returns a list of entry names
    def list(dirpath)
      Log.info "Namespace list contents of #{dirpath}"
      
      base, rest = split_path(dirpath)
      
      # If we are asked for contents directly under current namespace,
      # just return the keys from @names. Else delegate the call to
      # the namespace object responsible for it.
      if base
        if baseobj = @names[File.basename(base)]
          baseobj.list(rest)
        else
          throw NonExistentPathError
        end
      else
        @names.keys
      end
      
    end
    
    def metadata(path)
      Log.info "Namespace metadata for #{path}"
      
      base, rest = split_path(path)
      
      if base == '/'
        throw UnexpectedError
      else
        if baseobj = @names[File.basename(base)]
          baseobj.metadata(rest)
        else
          throw NonExistentPathError
        end
        
      end
    end
    
    def readfile(path)
      base, rest = split_path(path)
      
      if base and base_obj = @names[File.basename(base)]
        base_obj.readfile(rest)
      else
        throw NonExistentPathError
      end
      
    end # readfile
    
    def writefile(path, data)
      Log.info "Namespace writefile to #{path}"
      
      base, rest = split_path(path)
      
      if base and base_obj = @names[File.basename(base)]
        base_obj.writefile(rest, data)
      else
        throw NonExistentPathError
      end
      
    end # writefile
    
    def mkdir(path)
      Log.info "Namespace make directory #{path}"
      
      base, rest = split_path(path)
      
      if base and base_obj = @names[File.basename(base)]
        base_obj.mkdir(rest)
      else
        throw NonExistentPathError
      end
      
    end # mkdir
    
    def delete(path)
      Log.info "Namespace delete path #{path}"
      
      base, rest = split_path(path)
      
      if base and base_obj = @names[File.basename(base)]
        base_obj.delete(rest)
      else
        throw NonExistentPathError
      end
      
    end # mkdir
    
  end # Namespace<dynamic>
  
end ; end

#
# module McFS; module Service
#
#   # A namespace is a mountable volume
#   class Namespace
#     include Celluloid
#
#     attr_reader :name
#
#     def initialize(name)
#       @name = name
#       @stores = {}
#     end # initialize
#
#     # Adds a store to the namespace
#     #
#     # @param store [Store] the store to be added
#     #
#     # @return [Store] the same store
#     def add_store(store)
#       # TODO: needs to check if store name exits?
#       @stores[store.name] = store
#     end
#
#
#     def listfiles(dirpath)
#       Log.info "Listing files under : #{dirpath}"
#
#       if dirpath == '/'
#         @stores.collect do |name, store|
#           {
#             'name' => name,
#             'dir?' => true,
#             'size' => 0,
#             'server_mtime' => nil,
#             'client_mtime' => nil
#           }
#         end
#       else
#         base, rest = split_path(dirpath)
#
#         # Ensure the directory name ends with a /
#         # rest += '/' if rest[-1] != '/'
#
#         store = @stores[base]
#         if store
#           Log.info "Listing #{base} store under #{rest}"
#           store.get_dirmeta(rest)
#         else
#           # TODO: throw exception
#           []
#         end
#       end
#
#     end # listfiles
#
#     # List of all namespaces created
#     @@repository = {}
#
#     def self.create(name)
#       if @@repository.has_key? name
#         nil
#       else
#         @@repository[name] = Namespace.new(name)
#       end
#     end # create_namespace
#
#     def self.list
#       @@repository.keys
#     end
#
#     def self.get(name)
#       @@repository[name]
#     end
#
#     def self.listfiles(ns, dirpath)
#       @@repository[ns].listfiles(dirpath)
#     end
#
#     DEFAULT_NAMESPACE = create('default')
#
#   end # Namespace
#
# end; end
