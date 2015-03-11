
#TODO: need to use Logger for logging

require 'rfusefs'

require_relative 'mcfs/filesystem'
require_relative 'mcfs/service'

Thread.new do
  McFS::Service.run!(:port=>0)
end

FuseFS.main do |opts|
  McFS::Filesystem.new
end
