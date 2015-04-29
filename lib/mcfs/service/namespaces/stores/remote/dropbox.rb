
require 'dropbox_sdk'

require_relative 'remote_store'

module McFS; module Service; module Stores
  
  class Dropbox < RemoteStore
    
    def initialize(nsid, token)
      super nsid
      # TODO: re-think if we really need to store the token
      @token = token
      @client = DropboxClient.new(token)
      
      Log.info "New dropbox account added for #{@client.account_info['display_name']}"
    end
    
    # Retrieve metadata of a directory
    #
    # @return DirMeta
    #
    # dirpath is expected to be a directory
    def dirmeta(dirpath)
      Log.info "Getting dropbox metadata for #{dirpath}"
      
      # Get metadata of the directory from Dropbox server
      metadata = @client.metadata(dirpath)
      
      pp metadata
      
      dir_meta = create_metadata(metadata)
      
      unless dir_meta.is_a? DirMeta
        throw something
      end
      
      metadata['contents'].each do |entry|        
        dir_meta.add_entry create_metadata(entry)
      end
      
      dir_meta
      
    end # dirmeta(dirpath)
    
    def readfile(path)
      Log.info "Dropbox readfile #{path}"
      
      data, metadata = @client.get_file_and_metadata(path)
      
      {
        'data' => data,
        'size' => metadata['bytes']
      }
    end
    
    def writefile(path, data)
      Log.info "Dropbox writefile to #{path}"
      
      metadata = @client.put_file(path, data, true)

      pp metadata
        
      update_metadata(path, create_metadata(metadata))
    end
    
    # def can_delete?(path)
    #   true
    # end
    #
    def delete(path)
      Log.info "Dropbox delete #{path}"

      metadata = @client.file_delete(path)
      
      pp metadata
      
      update_metadata(path, create_metadata(metadata))
    end
    
    # def can_mkdir?(path)
    #   true
    # end
    #
    def mkdir(path)
      Log.info "Dropbox mkdir #{path}"

      metadata = @client.file_create_folder(path)
    
      pp metadata
        
      update_metadata(path, create_metadata(metadata))
    end # mkdir
    
    # def can_rmdir?(path)
    #   true
    # end
    #
    alias_method :rmdir, :delete
    
    private
    
    # Create a MetaData(DirMeta/FileMeta) from the metadata hash
    # provided by dropbox sdk
    def create_metadata(metadata)
      name  = File.basename(metadata['path'])
      size  = metadata['bytes']
      mtime = metadata['modified']
      
      meta = if metadata['is_dir']
        DirMeta.new(name, mtime)
      else
        FileMeta.new(name, size, mtime)
      end
      
      if metadata['is_deleted']
        meta.deleted = true
      end
      
      meta
      
    end # create_metadata
    
  end # Dropbox
  
  Store.add_service('dropbox', Dropbox)
  
  # class Dropbox < Store
  #
  #   INACTIVITY_TIMEOUT = 5
  #
  #   def initialize(name, token)
  #     super(name)
  #
  #     @token = token
  #
  #     @client = DropboxClient.new(token)
  #
  #     Log.info 'Fetching Dropbox account information...'
  #     @account_info = @client.account_info
  #
  #     Log.info "Dropbox user is identified as #{user_identity}"
  #
  #     # { dir => metadata } temporal cache: cleared during every
  #     # INACTIVITY_TIMEOUT seconds. Better method is to timestamp
  #     # each entry and check for each access.
  #     @metadata = {}
  #
  #     mkdir '/McFS' unless directory? '/McFS'
  #
  #   end
  #
  #   def stop_timer
  #     if @timer
  #       @timer.cancel
  #       @timer = nil
  #     end
  #   end
  #
  #   def reset_timer
  #     if @timer
  #       @timer.cancel
  #     end
  #     @timer = every(INACTIVITY_TIMEOUT) { @metadata.clear }
  #   end
  #
  #   def user_identity
  #     "#{@account_info['uid']}(#{@account_info['display_name']})"
  #   end
  #
  #   def identity
  #     "#{@account_info['uid']}@dropbox.com"
  #   end
  #
  #   def info
  #     {
  #       'service' => 'Dropbox',
  #       'uid' => @account_info['uid'],
  #       'name' => @account_info['display_name'],
  #       'capacity' => @account_info['quota_info']['quota'],
  #       'used' => @account_info['quota_info']['normal'],
  #       'token' => @token
  #     }
  #   end
  #
  #   # def download_metadata(dir)
  #   #   Log.info "[#{user_identity}] Fetching Dropbox metadata for #{dir}..."
  #   #
  #   #   @metadata[dir] = @client.metadata(dir)
  #   #   @metadata[dir]['contents'].each do |entry|
  #   #     download_metadata(entry['path']) if entry['is_dir']
  #   #   end
  #   # end
  #   #
  #   # # list contents under directory
  #   # def contents(dir)
  #   #   Log.info "[#{user_identity}] Listing contents under #{dir}..."
  #   #
  #   #   # entry['path'].split('/')[-1]
  #   #   # TODO: File.basename may have issues with path separator
  #   #   # FIXME: need to handle the case when metadata returns nil.
  #   #   @metadata[dir]['contents'].collect {|e| File.basename(e['path']) }
  #   # end
  #
  #   def contents(dir)
  #     dir = dir.sub(/\/+$/,'')
  #
  #     Log.info "[#{user_identity}]: ls #{dir}..."
  #
  #     stop_timer
  #
  #     begin
  #       @metadata[dir] = @client.metadata(dir) unless @metadata.has_key?(dir)
  #       @metadata[dir]['contents'].collect {|e| File.basename(e['path']) }
  #     ensure
  #       reset_timer
  #     end
  #   end
  #
  #   def metadata_has_dir?(dir)
  #     @metadata.has_key?(dir)
  #   end
  #
  #   def metadata_for_dir(dir)
  #     @metadata[dir] = @client.metadata(dir) unless metadata_has_dir?(dir)
  #     @metadata[dir]
  #   end
  #
  #   # def directory?(path)
  #   #   @metadata.has_key?(path)
  #   # end
  #
  #   def directory?(path)
  #     path = path.sub(/\/+$/,'')
  #
  #     Log.info "[#{user_identity}]: dir? #{path}..."
  #
  #     stop_timer
  #
  #     begin
  #       # Return true if we have direct metadata in cache
  #       return true if metadata_has_dir?(path)
  #
  #       # Lookup parent's metadata to find the type of
  #       # entry
  #       parent = File.dirname(path)
  #       pmeta = metadata_for_dir(parent)
  #
  #       pmeta['contents'].each do |ent|
  #         if ent['path'] == path and ent['is_dir'] == true
  #           return true
  #         end
  #       end
  #
  #       return false
  #     ensure
  #       reset_timer
  #     end
  #
  #   end
  #
  #   def can_mkdir?(path)
  #     true
  #   end
  #
  #   # def times(path)
  #   # end
  #
  #   # def file?(path)
  #   #   if meta = @metadata[File.dirname(path)]
  #   #     meta['contents'].detect {|e| e['path'] == path }
  #   #   end
  #   # end
  #
  #   def file?(path)
  #     path = path.sub(/\/+$/,'')
  #
  #     Log.info "[#{user_identity}]: file? #{path}..."
  #
  #     stop_timer
  #
  #     begin
  #       # Return false if we have direct metadata in cache
  #       return false if metadata_has_dir?(path)
  #
  #       # Lookup parent's metadata to find the type of
  #       # entry
  #       parent = File.dirname(path)
  #       pmeta = metadata_for_dir(parent)
  #       #
  #       # pp pmeta
  #
  #       pmeta['contents'].each do |ent|
  #         if ent['path'] == path and ent['is_dir'] == false
  #           return true
  #         end
  #       end
  #
  #       return false
  #     ensure
  #       reset_timer
  #     end
  #   end
  #
  #   # Everything is writable in Dropbox
  #   def can_write?(path)
  #     true
  #   end
  #
  #   def executable?(path)
  #     path = path.sub(/\/+$/,'')
  #
  #     Log.info "[#{user_identity}]: exec? #{path}..."
  #     directory? path
  #   end
  #
  #   # Size of a file in bytes
  #   def size(path)
  #     path = path.sub(/\/+$/,'')
  #
  #     Log.info "[#{user_identity}]: size? #{path}..."
  #
  #     stop_timer
  #
  #     begin
  #       # Lookup parent's metadata to find the type of
  #       # entry
  #       parent = File.dirname(path)
  #       pmeta = metadata_for_dir(parent)
  #
  #       # meta = @metadata[File.dirname(path)]['contents'].find {|e| e['path'] == path }
  #       # meta['bytes']
  #       if meta = pmeta['contents'].find {|e| e['path'] == path }
  #         meta['bytes']
  #       else
  #         0
  #       end
  #     ensure
  #       reset_timer
  #     end
  #
  #   end
  #
  #   def read_file(path)
  #     path = path.sub(/\/+$/,'')
  #
  #     Log.info "[#{user_identity}]: read #{path}..."
  #
  #     stop_timer
  #
  #     begin
  #       data, metadata = @client.get_file_and_metadata(path)
  #
  #       # Lookup parent's metadata to update metadata of this file
  #       parent = File.dirname(path)
  #       pmeta = metadata_for_dir(parent)
  #
  #       pmeta['contents'].delete_if {|e| e['path'] == metadata['path']}
  #       pmeta['contents'] << metadata
  #       # if ometa = pmeta['contents'].find {|e| e['path'] == path }
  #       #   ometa.merge!(metadata)
  #       # else
  #       #   pmeta['contents'] << metadata
  #       # end
  #
  #     ensure
  #       reset_timer
  #     end
  #
  #     data
  #   end
  #
  #   def write_to(path, str)
  #     path = path.sub(/\/+$/,'')
  #
  #     Log.info "[#{user_identity}]: write #{path}..."
  #
  #     stop_timer
  #
  #     begin
  #       metadata = @client.put_file(path, str, true)
  #
  #       # Lookup parent's metadata to update file's metadata
  #       parent = File.dirname(path)
  #       pmeta = metadata_for_dir(parent)
  #
  #       pmeta['contents'].delete_if {|e| e['path'] == metadata['path']}
  #       pmeta['contents'] << metadata
  #       # if ometa = pmeta['contents'].find {|e| e['path'] == metadata['path'] }
  #       #   ometa.merge!(metadata)
  #       # else
  #       #   pmeta['contents'] << metadata
  #       # end
  #     ensure
  #       reset_timer
  #     end
  #   end
  #
  #   def can_delete?(path)
  #     path = path.sub(/\/+$/,'')
  #
  #     file? path
  #   end
  #
  #   def delete(path)
  #     path = path.sub(/\/+$/,'')
  #
  #     Log.info "[#{user_identity}]: rm #{path}..."
  #
  #     stop_timer
  #
  #     begin
  #       metadata = @client.file_delete(path)
  #
  #       # Lookup parent's metadata to delete file's metadata
  #       parent = File.dirname(path)
  #       pmeta = metadata_for_dir(parent)
  #
  #       pmeta['contents'].delete_if {|e| e['path'] == metadata['path']}
  #     ensure
  #       reset_timer
  #     end
  #   end
  #
  #   def can_mkdir?(path)
  #     true
  #   end
  #
  #   def mkdir(path)
  #     path = path.sub(/\/+$/,'')
  #
  #     Log.info "[#{user_identity}]: mkdir #{path}..."
  #
  #     stop_timer
  #
  #     begin
  #       @metadata[path] = @client.file_create_folder(path)
  #     ensure
  #       reset_timer
  #     end
  #   end
  #
  #   def can_rmdir?(path)
  #     #FIXME
  #     false
  #   end
  #
  #   def rmdir(path)
  #     #FIXME
  #     nil
  #   end
  #
  #   # def read_file(path)
  #   #   puts "Read: #{path}"
  #   #
  #   #   filenames = @client.metadata(File.dirname('/McFS' + path))['contents'].map do |e|
  #   #     e['path'] if File.basename(e['path'], '.*') == File.basename('/McFS' + path)
  #   #   end
  #   #
  #   #   contents = {}
  #   #
  #   #   filenames.each do |file|
  #   #     if file then
  #   #       puts file
  #   #
  #   #       index = File.extname(file)[1..-1].to_i
  #   #       data, metadata = @client.get_file_and_metadata(file)
  #   #       contents[index] = data
  #   #     end
  #   #   end
  #   #
  #   #   return contents
  #   # end
  #   #
  #   # def write_to(path, index, str)
  #   #   puts "write: #{path}, #{index}, #{str}"
  #   #   @client.put_file('/McFS' + path + ".#{index}", str, true)
  #   # end
  #
  # end # Dropbox

end; end; end
