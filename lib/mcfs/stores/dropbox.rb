require 'dropbox_sdk'

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

  class Dropbox
    
    def initialize(token)
      @client = DropboxClient.new(token)
    end
    
    # list contents under directory
    def contents(dir)
      puts "Path: #{dir}"
      @client.metadata('/McFS' + dir)['contents'].map do |entry|
        # entry['path'].split('/')[-1]
        # TODO: File.basename may have issues with path separator
        File.basename(entry['path'], '.*')
      end
    end
    
    def read_file(path)
      filenames = @client.metadata(File.dirname('/McFS' + path))['contents'].map do |e|
        e['path'] if File.basename(e['path'], '.*') == File.basename('/McFS' + path)
      end
      
      contents = {}
      
      filenames.each do |file|
        if file then
          puts file
        
          index = File.extname(file)[1..-1].to_i
          data, metadata = @client.get_file_and_metadata(file)
          contents[index] = data
        end
      end
      
      return contents
    end
    
    def write_to(path, index, str)
      puts "write: #{path}, #{index}, #{str}"
      @client.put_file('/McFS' + path + ".#{index}", str, true)
    end
    
  end
end
end
