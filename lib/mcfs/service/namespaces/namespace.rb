
module McFS; module Service
  # Namespaces provide a mechanism to combine one of more
  # namespaces without name collisions
  class Namespace
    
  end
  
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
#     # Return [base, rest]
#     def split_path(path)
#       base, *rest = path.scan(/[^\/]+/)
#
#       [ base, '/' + File.join(rest) ]
#     end
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
