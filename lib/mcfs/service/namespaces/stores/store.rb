
module McFS; module Service
  
  # Abstract class that need to be implemented by all
  # storage services
  class Store < Namespace
    
    include Celluloid
    
    # Maps service names to its store classes
    @@services = { }
    
    # Repository of all stores created within this service
    @@repo = { }
    
    attr_reader :uuid
    
    # Not sure what arguments are needed for intialization
    def initialize(uuid)
      @uuid = uuid
      
      # FIXME: probably need to check if uuid is present
      @@repo[@uuid] = self
    end
    
    # # need to be implemented by all stores
    # def name
    #   abort 'Unimplemented method: #{self.class}##{__method__}'
    # end
    #
    
    def self.add_service(name, klass)
      @@services[name] = klass
    end
    
    # TODO: probably need to use Forwardable to delegate to @@repo
    
    def self.find(&block)
      @@repo.detect &block
    end
    
    def self.each(&block)
      @@repo.each &block
    end
    
    def self.collect(&block)
      @@repo.collect &block
    end
    
    # Add a new store to the repository
    def self.add(uuid, service, token)
      if @@repo.has_key? uuid
        # TODO: throw proper error
        return nil
      end
      
      # TODO: load the class instead by namespace lookup under
      #       McFS::Service::Stores module (will be much cleaner)
      if service_klass = @@services[service]
        service_klass.new(uuid, token)
      else
        # FIXME: throw unknown service exception
        #        returning nil for now
      end
      
    end
    
    # TODO: define abstract methods needed to operate on a store
    
  end # Store
  
end; end
