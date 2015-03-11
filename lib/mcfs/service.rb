
require 'sinatra/base'

module McFS
  class Service < Sinatra::Base
    get '/' do
      'McFS Service'
    end
  end
end
