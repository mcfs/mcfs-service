
require_relative 'resource'

module McFS; module Service
  
  # For now keeping config here
  class Config
    @@config = []
    
    def self.updates(lastid)
      id = lastid ? lastid + 1 : 0
      
      if config = @@config[id]
        {
          'id' => id,
          'path' => config[0],
          'cmd' => config[1]
        }
      end
    end # self.updates
    
    def self.add(path, cmd)
      @@config << [path, cmd]
    end
    
  end # Config
  
  class ConfigResource < McFSResource
    
    # def action_get_list
    # end
    
    def action_post_updates
      Log.info "Config updates request"
      
      lastid = request_data['lastid']
      
      McFS::Service::Config.updates(lastid)
    end # add_share
    
  end #SharesResource
  
end; end
