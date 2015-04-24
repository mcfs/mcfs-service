
# Namespaces provide a mechanism to combine one of more
# namespaces without name collisions

module McFS; module Service
  
  # Define all class variables and methods
  class Namespace
    
    # Repository that maps all namespaces from their uuid
    # uuid(String) => Namespace
    @@repo = {}
    
    # TODO: probably need to use Forwardable to delegate to @@repo
    
    def self.has_uuid?(uuid)
      @@repo.has_key? uuid
    end
    
    def self.add_uuid(uuid, nsobj)
      # FIXME: implement the following exception
      # throw <exception> if @@repo.has_key? uuid
      @@repo[uuid] = nsobj
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
    
    # Every namespace has a unique identifier
    attr_reader :uuid, :names
    
    # Not sure what arguments are needed for intialization
    def initialize(uuid)
      # FIXME: add checks for validating the format of uuid string
      @uuid = uuid
      
      # Maps from a name to its namespace handler
      # name(String) => Namespace
      @names = {}
      
      self.class.add_uuid(uuid, self)
    end
    
    # Return [base, rest]
    def split_path(path)
      base, *rest = path.scan(/[^\/]+/)
      [ base, '/' + File.join(rest) ]
    end
    
    # Returns a list of entry names
    def list(dirpath)
      base, rest = split_path(dirpath)
      
      # If we are asked for contents directly under current namespace,
      # just return the keys from @names. Else delegate the call to
      # the namespace object responsible for it.
      if base == '/'
        @names.keys
      else
        if baseobj = @names[File.basename(base)]
          baseobj.list(rest)
        else
          throw NonExistentPathError
        end
        
      end
      
    end
    
    # Given a path return true if it's a file
    def file?(path)
    end
    
    # Given a path return true if it's a directory
    def dir?(path)
    end
    
    def mkdir(dirpath, nsobj)
      base, rest = split_path(dirpath)
      
      if base == '/'
        throw InvalidPathError
      end
      
      if rest.empty?
        @names[File.basename(base)] = nsobj
      else
        if baseobj = @names[File.basename(base)]
          baseobj.mkdir(rest, nsobj)
        else
          throw NonExistentPathError
        end
        
      end
    end
    
    def rmdir(name)
      throw UnimplementedMethodError
      @names.delete(name)
    end
        
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
