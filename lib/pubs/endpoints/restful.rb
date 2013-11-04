require 'goliath/api'
require 'pubs/endpoints/helpers/router'
require 'pubs/rack/session'

module Pubs
  module Endpoints
    class RESTful < Goliath::API

      include Helpers::Router
      include Pubs::Rack::Session::Helper

      class << self
        def inherited(klass)
          klass.use Goliath::Rack::Heartbeat
          klass.use Goliath::Rack::Params
          klass.use Goliath::Rack::Render
          klass.use Goliath::Rack::DefaultMimeType
          klass.use Goliath::Rack::SimpleAroundwareFactory, Pubs::Rack::Session, "pubs-io"
          super
        end
      end

    end
  end
end
