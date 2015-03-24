
require 'date'
require_relative 'lib/mcfs/version'

Gem::Specification.new do |gem|
  gem.name        = 'mcfs'
  gem.version     = McFS::VERSION
  gem.date        = Date.today
  gem.summary     = 'mcfs summary'
  gem.description = 'mcfs description'
  gem.authors     = [ 'Jinesh Jayakumar' ]
  gem.email       = 'jineshkj at gmail dot com'
  gem.homepage    = 'https://github.com/mcfs/mcfs'
  gem.license     = 'LGPLv3'

  gem.add_runtime_dependency 'dropbox-sdk', '~> 1.6', '= 1.6.4'
  gem.add_runtime_dependency 'rfusefs', '~> 1.0', '= 1.0.3'
  gem.add_runtime_dependency 'celluloid', '~> 0.16', '= 0.16.0'
  gem.add_runtime_dependency 'reel', '~> 0.5', '= 0.5.0'
  gem.add_runtime_dependency 'webmachine', '~> 1.4', '= 1.4.0'
  gem.add_runtime_dependency 'rpam-ruby19', '~> 1.2', '= 1.2.1'
  
  gem.files =
  [
    'bin/mcfs',
    'lib/mcfs.rb',
    'lib/mcfs/version.rb',
    'lib/mcfs/config.rb',
    'lib/mcfs/filesystem.rb',
    'lib/mcfs/stores/dropbox.rb',
    'lib/mcfs/api/rest/service.rb',
    'lib/mcfs/api/rest/resources/login.rb'
  ]
  gem.executables = [ 'mcfs' ]
end
