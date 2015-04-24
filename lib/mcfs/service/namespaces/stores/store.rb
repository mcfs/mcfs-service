
module McFS; module Service
  
  # Define class variables and methods
  class Store < Namespace
    
    # Maps service names to its store classes
    @@services = { }
        
    def self.add_service(name, klass)
      @@services[name] = klass
    end
    
    # Add a new store to the repository
    def self.instantiate(service, uuid, token)
      
      # FIXME: catch NameError raised when the name does not exist
      klass = McFS::Service::Stores::const_get(service)
      
      # Ensure klass is a sub-class of RemoteStore
      if klass < RemoteStore
        klass.new(uuid, token)
      else
        # FIXME: throw exception
        throw StoreNotSupportedError
      end
      
    end # instantiate()
    
  end # Store<static>
    
  # Abstract class that need to be implemented by all
  # storage services
  class Store < Namespace
    
    include Celluloid    
    
    # TODO: define abstract methods needed to operate on a store
    
  end # Store<dynamic>
  
end; end
