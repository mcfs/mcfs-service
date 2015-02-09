
Gem::Specification.new do |gem|
  gem.name        = 'mcfs'
  gem.version     = '0.0.0'
  gem.date        = '2015-02-08'
  gem.summary     = 'mcfs summary'
  gem.description = 'mcfs description'
  gem.authors     = ["Jinesh Jayakumar"]
  gem.email       = 'jineshkj at gmail dot com'
  gem.files       = ['lib/mcfs.rb']
  gem.homepage    = 'https://github.com/jineshkj/mcfs'
  gem.license     = 'LGPLv3'

  gem.add_runtime_dependency 'dropbox-sdk', '~> 1.6', '= 1.6.4'
end
