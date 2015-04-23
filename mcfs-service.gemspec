
require 'date'
require_relative 'lib/mcfs/service/version'

Gem::Specification.new do |gem|
  gem.name        = 'mcfs-service'
  gem.version     = McFS::Service::VERSION
  gem.date        = Date.today
  gem.summary     = 'mcfs service'
  gem.description = 'mcfs service description'
  gem.authors     = [ 'Jinesh Jayakumar' ]
  gem.email       = 'jineshkj at gmail dot com'
  gem.homepage    = 'https://github.com/mcfs/mcfs-service'
  gem.license     = 'LGPLv3'

  gem.add_runtime_dependency 'commander'

  gem.add_runtime_dependency 'celluloid', '~> 0.16', '= 0.16.0'
  gem.add_runtime_dependency 'reel', '~> 0.5', '= 0.5.0'
  gem.add_runtime_dependency 'webmachine', '~> 1.4', '= 1.4.0'
  
  # Dependencies for third-party cloud services
  gem.add_runtime_dependency 'dropbox-sdk', '~> 1.6', '= 1.6.4'

  # gem.files =
  # [
  #   'bin/mcfs-service',
  #   'lib/mcfs.rb',
  #   'lib/mcfs/version.rb',
  #   'lib/mcfs/config.rb',
  #   'lib/mcfs/filesystem.rb',
  #   'lib/mcfs/stores/dropbox.rb',
  #   'lib/mcfs/api/rest/service.rb',
  #   'lib/mcfs/api/rest/resources/login.rb'
  # ]
  # gem.executables = [ 'mcfs-service' ]
end
