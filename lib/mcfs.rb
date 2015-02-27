
# TODO: need to move dropbox to separate adapter
require 'rfusefs'

require_relative 'mcfs/filesystem'

FuseFS.main do |opts|
  McFS::Filesystem.new
end
