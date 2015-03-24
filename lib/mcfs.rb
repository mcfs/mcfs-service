
require 'logger'

module McFS
  MCFS_DIR  = '.mcfs'
  MCFS_DIR_PATH = File.join(Dir.home, MCFS_DIR)
  MCFS_LOG_PATH = File.join(MCFS_DIR_PATH, 'mcfs.log')
  
  Dir.mkdir(MCFS_DIR_PATH, 0700) unless Dir.exists?(MCFS_DIR_PATH)
  # Log = Logger.new(MCFS_LOG_PATH)
  Log = Logger.new(STDOUT)
end

#TODO: need to use Logger for logging

require 'fusefs'

require_relative 'mcfs/config'
require_relative 'mcfs/filesystem'
require_relative 'mcfs/api/rest/service'

Thread.new do
  McFS::RESTService.run
end

FuseFS.main do |opts|
  McFS::Filesystem.new
end
