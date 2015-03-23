require 'celluloid'
require 'dropbox_sdk'

#TODO: replace DropboxConfig with a generic structure like ostruct
class DropboxConfig
  attr_reader :app_key, :app_secret, :access_token, :user_id
  
  def initialize(key, secret, token, user)
    @app_key = key
    @app_secret = secret
    @access_token = token
    @user_id = user
  end
end

module McFS
module Stores

  class Dropbox < FuseFS::FuseDir
    
    include Celluloid
    
    def initialize(token)
      @client = DropboxClient.new(token)
      
      Log.info 'Fetching Dropbox account information...'
      @account_info = @client.account_info
      
      Log.info "Dropbox user is identified as #{user_identity}"
      
      @metadata = {}
      download_metadata '/'
    end
    
    def user_identity
      "#{@account_info['uid']}(#{@account_info['display_name']})"
    end
    
    def identity
      "#{@account_info['uid']}@dropbox.com"
    end
    
    def download_metadata(dir)
      Log.info "[#{user_identity}] Fetching Dropbox metadata for #{dir}..."
      
      @metadata[dir] = @client.metadata(dir)
      @metadata[dir]['contents'].each do |entry|
        download_metadata(entry['path']) if entry['is_dir']
      end
    end
        
    # list contents under directory
    def contents(dir)
      Log.info "[#{user_identity}] Listing contents under #{dir}..."
      
      # entry['path'].split('/')[-1]
      # TODO: File.basename may have issues with path separator
      # FIXME: need to handle the case when metadata returns nil.
      @metadata[dir]['contents'].collect {|e| File.basename(e['path']) }
    end

    def directory?(path)
      @metadata.has_key?(path)
    end

    def can_mkdir?(path)
      true
    end

    # def times(path)
    # end
    
    def file?(path)
      if meta = @metadata[File.dirname(path)]
        meta['contents'].detect {|e| e['path'] == path }
      end
    end

    # Everything is writable in Dropbox
    def can_write?(path)
      true
    end

    def executable?(path)
      # Only directories have execute permission
      @metadata.has_key?(path)
    end

    # Size of a file in bytes
    def size(path)
      meta = @metadata[File.dirname(path)]['contents'].find {|e| e['path'] == path }
      meta['bytes']
    end
    
    def read_file(path)
      @client.get_file(path)
    end
    
    def write_to(path, str)
      meta = @client.put_file(path, str, true)
      
      # Update metadata
      dir  = @metadata[File.dirname(path)]['contents']
      if orig = dir.find {|e| e['path'] == path }
        orig.merge!(meta)
      else
        dir << meta
      end
    end
    
    def can_delete?(path)
      true
    end
    
    def delete(path)
      meta = @client.file_delete(path)
      @metadata[File.dirname(meta['path'])]['contents'].delete_if {|e| e['path'] == meta['path']}
    end
    
    def can_mkdir?(path)
      true
    end
    
    def mkdir(path)
      @metadata[path] = @client.file_create_folder(path)
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
