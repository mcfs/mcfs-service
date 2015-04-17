
require 'yaml'
require 'pathname'
require 'net/http'

require_relative 'stores/dropbox'
require_relative 'stores/mcfsshare'

module McFS
  #TODO: implement the top-level layout using FuseFS::MetaDir virtual FS
  class Filesystem < FuseFS::MetaDir
    
    def initialize
      super
      # @stores = {}
      
      cfgfile = File.join(MCFS_DIR_PATH,'config.yml')
      if File.exists? cfgfile
        # Load an existing config is existing (for master node)
        Psych.load_file(cfgfile)['accounts'].each do |ac|
          add_account ac
        end
      else
        # On slaves we currently do frequent polling to update
        # config updates until proper push notification mechanisms
        # are figured out.
        Thread.new do
          loop do
            sleep 1
            
            accs = YAML.load(Net::HTTP.get('10.0.2.2', '/accounts', 3000))
            
            accs.each do |ac|
              
              unless @subdirs.detect {|dir,store| ac['uid'] == store.info['uid'] }
                puts "New account: #{ac}"
                add_account ac
              end
            end
            
          end
        end
        
      end
      
      mkdir('/McFS', McFS::Stores::McFSShare.new(self))
    end

    def accounts
      # Accessing @subdirs from FuseFS::MetaDir
      @subdirs.collect do |dir,store|
        store.info.merge!({ 'mount' => dir }) if dir != 'McFS'
      end.compact!
    end
    
    def stores
      @subdirs.collect do |dir,store|
        store if dir != 'McFS'
      end.compact!
    end
    
    def add_account(ac)
      store = Stores::Dropbox.new(ac['token'])
      mkdir('/' + store.identity, store)
      
      # store = Stores::Dropbox.new(ac['token'])
      # @stores[store.identity] = store
    end
    
    # def contents(dir)
    #   if dir == '/'
    #     @stores.keys
    #   else
    #     root,store,path = dir.partition(/[^\/]+/)
    #     @stores[store].contents(File.join(root,path))
    #   end
    # end
    
    # def contents(path)
    #   files = []
    #
    #   futures = []
    #   @stores.each do |store|
    #     futures << store.future.contents(path)
    #   end
    #
    #   futures.each do |future|
    #     files += future.value
    #   end
    #
    #   files.uniq
    # end
    
    # def directory?(path)
    #   true
    # end
    #
    # def file?(path)
    #   true
    # end
    #
    # def can_write?(path)
    #   true
    # end
    #
    # def read_file(path)
    #   puts "Read File: #{path}"
    #   contents = {}
    #
    #   futures = []
    #   @stores.each do |store|
    #     futures << store.future.read_file(path)
    #   end
    #
    #   futures.each do |future|
    #     contents.merge! future.value
    #   end
    #
    #   data = ''
    #
    #   contents.sort.each do |chunk|
    #     data << chunk[1]
    #   end
    #
    #   data
    # end
    #
    # def write_to(path, str)
    #   puts "write_to: #{path}, #{str}"
    #   buf = ''
    #   cnt = 0
    #   idx = 0
    #
    #   str.each_byte do |b|
    #     buf << b
    #     cnt += 1
    #
    #     if cnt == 4096 then
    #       @stores[idx % @stores.size].write_to(path, idx, buf)
    #       buf = ''
    #       idx += 1
    #       cnt = 0
    #     end
    #   end
    #
    #   if buf.size > 0 then
    #     puts buf.size
    #     puts idx
    #     p @stores
    #     puts @stores[idx % (@stores.size)]
    #     @stores[idx % @stores.size].write_to(path, idx, buf)
    #   end
    #
    # end
    
  end # Filesystem
end # McFS
