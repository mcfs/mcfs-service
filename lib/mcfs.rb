
# TODO: need to move dropbox to separate adapter
require 'dropbox_sdk'
require 'rfusefs'
require 'yaml'

# TODO: proper namespace

class DropBoxConfig
  attr_reader :app_key, :app_secret, :access_token, :user_id
  def initialize(key, secret, token, user)
    @app_key = key
    @app_secret = secret
    @access_token = token
    @user_id = user
  end
end

class McFS
  def initialize
    cfg = YAML.load_file(ENV['HOME'] + '/.mcfs.yml')
    # puts "Access: #{cfg.access_token}"
    @client = DropboxClient.new(cfg.access_token)
  end

  def contents(path)
    puts "Path: #{path}"
    list = []
    @client.metadata(path)['contents'].each_entry do |entry|
      list << entry['path'].split('/')[-1]
    end
    list
  end

  def file?(path)
    true
  end

  def read_file(path)
    "Meta: #{@client.metadata('/').to_s}"
  end
end

FuseFS.main do |opts|
  McFS.new
end
