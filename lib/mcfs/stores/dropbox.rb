require 'celluloid'
require 'dropbox_sdk'

# #TODO: replace DropboxClient with a generic structure like ostruct
# class DropboxConfig
#   attr_reader :app_key, :app_secret, :access_token, :user_id
#
#   def initialize(key, secret, token, user)
#     @app_key = key
#     @app_secret = secret
#     @access_token = token
#     @user_id = user
#   end
# end

module McFS
module Stores

  class Dropbox < FuseFS::FuseDir
    
    include Celluloid
    
    INACTIVITY_TIMEOUT = 5
    
    def initialize(token)
      @token = token
      
      @client = DropboxClient.new(token)
      
      Log.info 'Fetching Dropbox account information...'
      @account_info = @client.account_info
      
      Log.info "Dropbox user is identified as #{user_identity}"
      
      # { dir => metadata } temporal cache: cleared during every
      # INACTIVITY_TIMEOUT seconds. Better method is to timestamp
      # each entry and check for each access.
      @metadata = {}

      mkdir '/McFS' unless directory? '/McFS'
      
    end
    
    def stop_timer
      if @timer
        @timer.cancel
        @timer = nil
      end
    end
    
    def reset_timer
      if @timer
        @timer.cancel
      end
      @timer = every(INACTIVITY_TIMEOUT) { @metadata.clear }
    end
    
    def user_identity
      "#{@account_info['uid']}(#{@account_info['display_name']})"
    end
    
    def identity
      "#{@account_info['uid']}@dropbox.com"
    end
    
    def info
      {
        'service' => 'Dropbox',
        'uid' => @account_info['uid'],
        'name' => @account_info['display_name'],
        'capacity' => @account_info['quota_info']['quota'],
        'used' => @account_info['quota_info']['normal'],
        'token' => @token
      }
    end
    
    # def download_metadata(dir)
    #   Log.info "[#{user_identity}] Fetching Dropbox metadata for #{dir}..."
    #
    #   @metadata[dir] = @client.metadata(dir)
    #   @metadata[dir]['contents'].each do |entry|
    #     download_metadata(entry['path']) if entry['is_dir']
    #   end
    # end
    #
    # # list contents under directory
    # def contents(dir)
    #   Log.info "[#{user_identity}] Listing contents under #{dir}..."
    #
    #   # entry['path'].split('/')[-1]
    #   # TODO: File.basename may have issues with path separator
    #   # FIXME: need to handle the case when metadata returns nil.
    #   @metadata[dir]['contents'].collect {|e| File.basename(e['path']) }
    # end

    def contents(dir)
      Log.info "[#{user_identity}]: ls #{dir}..."
      
      stop_timer
      
      begin
        @metadata[dir] = @client.metadata(dir) unless @metadata.has_key?(dir)
        @metadata[dir]['contents'].collect {|e| File.basename(e['path']) }
      ensure
        reset_timer
      end
    end

    def metadata_has_dir?(dir)
      @metadata.has_key?(dir)
    end
    
    def metadata_for_dir(dir)
      @metadata[dir] = @client.metadata(dir) unless metadata_has_dir?(dir)
      @metadata[dir]
    end
    
    # def directory?(path)
    #   @metadata.has_key?(path)
    # end

    def directory?(path)
      Log.info "[#{user_identity}]: dir? #{path}..."
      
      stop_timer
      
      begin
        # Return true if we have direct metadata in cache
        return true if metadata_has_dir?(path)
        
        # Lookup parent's metadata to find the type of
        # entry
        parent = File.dirname(path)
        pmeta = metadata_for_dir(parent)
        
        pmeta['contents'].detect do |ent|
          ent['path'] == path and ent['is_dir']
        end
      ensure
        reset_timer
      end
      
    end

    def can_mkdir?(path)
      true
    end

    # def times(path)
    # end
    
    # def file?(path)
    #   if meta = @metadata[File.dirname(path)]
    #     meta['contents'].detect {|e| e['path'] == path }
    #   end
    # end

    def file?(path)
      Log.info "[#{user_identity}]: file? #{path}..."
      
      stop_timer
      
      begin
        # Return false if we have direct metadata in cache
        return false if metadata_has_dir?(path)
        
        # Lookup parent's metadata to find the type of
        # entry
        parent = File.dirname(path)
        pmeta = metadata_for_dir(parent)
        
        pmeta['contents'].detect do |ent|
          ent['path'] == path and not ent['is_dir']
        end
      ensure
        reset_timer
      end
    end

    # Everything is writable in Dropbox
    def can_write?(path)
      true
    end

    def executable?(path)
      Log.info "[#{user_identity}]: exec? #{path}..."
      directory? path
    end

    # Size of a file in bytes
    def size(path)
      Log.info "[#{user_identity}]: size? #{path}..."
      
      stop_timer
      
      begin
        # Lookup parent's metadata to find the type of
        # entry
        parent = File.dirname(path)
        pmeta = metadata_for_dir(parent)
      
        # meta = @metadata[File.dirname(path)]['contents'].find {|e| e['path'] == path }
        # meta['bytes']
        meta = pmeta['contents'].find {|e| e['path'] == path }
        meta['bytes']
      ensure
        reset_timer
      end
      
    end
    
    def read_file(path)
      Log.info "[#{user_identity}]: read #{path}..."
      
      stop_timer
      
      begin
        data, metadata = @client.get_file_and_metadata(path)
        
        # Lookup parent's metadata to update metadata of this file
        parent = File.dirname(path)
        pmeta = metadata_for_dir(parent)
        
        if ometa = pmeta['contents'].find {|e| e['path'] == path }
          ometa.merge!(metadata)
        else
          pmeta['contents'] << metadata
        end
        
      ensure
        reset_timer
      end
      
      data
    end
    
    def write_to(path, str)
      Log.info "[#{user_identity}]: write #{path}..."
      
      stop_timer
      
      begin
        metadata = @client.put_file(path, str, true)
        
        # Lookup parent's metadata to update file's metadata
        parent = File.dirname(path)
        pmeta = metadata_for_dir(parent)
        
        pmeta['contents'].delete_if {|e| e['path'] == metadata['path']}
        pmeta['contents'] << metadata
        
        # if ometa = pmeta['contents'].find {|e| e['path'] == metadata['path'] }
        #   ometa.merge!(metadata)
        # else
        #   pmeta['contents'] << metadata
        # end
      ensure
        reset_timer
      end
    end
    
    def can_delete?(path)
      true
    end
    
    def delete(path)
      Log.info "[#{user_identity}]: rm #{path}..."
      
      stop_timer
      
      begin
        metadata = @client.file_delete(path)
        
        # Lookup parent's metadata to delete file's metadata
        parent = File.dirname(path)
        pmeta = metadata_for_dir(parent)
        
        pmeta['contents'].delete_if {|e| e['path'] == metadata['path']}
      ensure
        reset_timer
      end
    end
    
    def can_mkdir?(path)
      true
    end
    
    def mkdir(path)
      Log.info "[#{user_identity}]: mkdir #{path}..."
      
      stop_timer
      
      begin
        @metadata[path] = @client.file_create_folder(path)
      ensure
        reset_timer
      end
    end
    
    def can_rmdir?(path)
      #FIXME
      false
    end
    
    def rmdir(path)
      #FIXME
      nil
    end
    
    # def read_file(path)
    #   puts "Read: #{path}"
    #
    #   filenames = @client.metadata(File.dirname('/McFS' + path))['contents'].map do |e|
    #     e['path'] if File.basename(e['path'], '.*') == File.basename('/McFS' + path)
    #   end
    #
    #   contents = {}
    #
    #   filenames.each do |file|
    #     if file then
    #       puts file
    #
    #       index = File.extname(file)[1..-1].to_i
    #       data, metadata = @client.get_file_and_metadata(file)
    #       contents[index] = data
    #     end
    #   end
    #
    #   return contents
    # end
    #
    # def write_to(path, index, str)
    #   puts "write: #{path}, #{index}, #{str}"
    #   @client.put_file('/McFS' + path + ".#{index}", str, true)
    # end
    
  end # Dropbox
end # Stores
end # McFS
