
require 'sinatra/base'

#TODO: replace Sinatra with Celluloid/Reel
module McFS
  class Service < Sinatra::Base
    get '/' do
      'McFS Service'
    end
  end
end
