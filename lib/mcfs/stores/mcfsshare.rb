require 'celluloid'

module McFS
module Stores

  class McFSShare < FuseFS::FuseDir
    
    # include Celluloid
    
    def initialize(fs)
      @fs = fs
    end
    
    def contents(dir)
      Log.info "[McFS]: ls #{dir}..."

      files = []

      futures = []
      @fs.stores.each do |store|
        futures << store.future.contents('/McFS' + dir)
      end

      futures.each do |future|
        future.value.each do |ent|
          files << File.basename(ent, '.*')
        end
        
      end

      files.uniq!
    end
    
    def info
      {
        'service' => 'McFSShare',
        'uid' => 0,
        'name' => '',
        'capacity' => 0,
        'used' => 0,
        'token' => ''
      }
    end
    
    def directory?(path)
      false
    end


    def can_mkdir?(path)
      false
    end

    # def times(path)
    # end
    
    # def file?(path)
    #   if meta = @metadata[File.dirname(path)]
    #     meta['contents'].detect {|e| e['path'] == path }
    #   end
    # end

    def file?(path)
      File.dirname(path) == '/'
    end

    # Everything is writable in Dropbox
    def can_write?(path)
      true
    end

    def executable?(path)
      false
    end

    # # Size of a file in bytes
    # def size(path)
    #   Log.info "[McFS]: size? #{path}..."
    #
    # end
    
    def read_file(path)
      Log.info "[McFS]: read #{path}..."
      
      futures = {}
      @fs.stores.each do |store|
        futures[store.future.contents('/McFS')] = store
      end
      
      contents = {}
      futures.each do |future, store|
        future.value.each do |ent|
          if File.basename(ent, '.*') == File.basename('/McFS' + path)
            index = File.extname(ent)[1..-1].to_i
            contents[index] = store.future.read_file('/McFS/' + ent)
          end
        end
      end
      
      data = ''
      contents.sort.each do |chunk|
        data << chunk[1].value
      end
      
      data
    end
    
    def write_to(path, str)
      Log.info "[McFS]: write #{path}..."
      
      delete(path)
      
      buf = ''
      cnt = 0
      idx = 0
      stores = @fs.stores
      
      wfutures = []
      
      str.each_byte do |b|
        buf << b
        cnt += 1
        
        if cnt == 4096 then
          wfutures << stores[idx % stores.size].future.write_to("/McFS#{path}.#{idx}", buf)
          buf = ''
          idx += 1
          cnt = 0
        end
      end
      
      if buf.size > 0 then
        wfutures << stores[idx % stores.size].future.write_to("/McFS#{path}.#{idx}", buf)
      end

      # Wait until the files are written
      wfutures.each { |future| future.value }

    end
    
    def can_delete?(path)
      true
    end
    
    def delete(path)
      Log.info "[McFS]: rm #{path}..."

      # First delete the existing files - unfortunately the only
      # way right now
      futures = {}
      @fs.stores.each do |store|
        futures[store.future.contents('/McFS')] = store
      end
      
      dfutures = []
      futures.each do |future, store|
        future.value.each do |ent|
          if File.basename(ent, '.*') == File.basename('/McFS' + path)
            dfutures << store.future.delete('/McFS/' + ent)
          end
        end
      end
      
      # Wait until the files are deleted
      dfutures.each { |future| future.value }

    end
    
    def can_mkdir?(path)
      false
    end
    
    # def mkdir(path)
    #   Log.info "[#{user_identity}]: mkdir #{path}..."
    #
    #   # @metadata[path] = @client.file_create_folder(path)
    #   @client.file_create_folder(path)
    # end
    
    def can_rmdir?(path)
      #FIXME
      false
    end
    
    def rmdir(path)
      #FIXME
      nil
    end
    
  end # McFSShare
end # Stores
end # McFS
