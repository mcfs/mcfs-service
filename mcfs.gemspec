
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
  gem.add_runtime_dependency 'sinatra', '~> 1.4', '= 1.4.5'

  gem.files =
  [
    'bin/mcfs',
    'lib/mcfs.rb',
    'lib/mcfs/version.rb',
    'lib/mcfs/config.rb',
    'lib/mcfs/filesystem.rb',
    'lib/mcfs/service.rb',
    'lib/mcfs/stores/dropbox.rb'
  ]
  gem.executables = [ 'mcfs' ]
end
