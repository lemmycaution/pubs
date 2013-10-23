require 'goliath/api'
require 'goliath/websocket'
require 'pubs/endpoints/helpers/router'
require 'pubs/rack/session'
require 'pubs/channels'
module Pubs
  module Endpoints
    class WebSocket < Goliath::WebSocket
      
      include Helpers::Router
      include Pubs::Rack::Session::Helper
      
      class << self
        def inherited(klass)
          klass.use Goliath::Rack::Heartbeat
          klass.use Goliath::Rack::Params
          klass.use Goliath::Rack::Render
          klass.use Goliath::Rack::DefaultMimeType  
          klass.use Goliath::Rack::SimpleAroundwareFactory, Pubs::Rack::Session
          super
        end
      end      
      
      def on_open(env)
        env.logger.info("WS OPEN")
        env['subscription'] = Pubs.channel.subscribe { |m| env.stream_send(m) }
      end

      def on_message(env, msg)
        env.logger.info("WS MESSAGE: #{msg}")
        Pubs.channel << msg
      end

      def on_close(env)
        env.logger.info("WS CLOSED")
        Pubs.channel.unsubscribe(env['subscription'])
      end

      def on_error(env, error)
        env.logger.error error
      end
      
      def on_body(env, data)
        if env.respond_to? :handler
          super env, data
        else
          (env['rack.input'] ||= '') << data
        end
      end
      
      def env
        @env
      end
      
      def response(env)
        @env = env
        
        if env["REQUEST_PATH"].start_with? '/ws'
          # super(env)
          # we need to call super.super
          # so this ugly hach is here
          grandparent = self.class.superclass.superclass
          meth = grandparent.instance_method(:response)
          meth.bind(self).call(env)
        else
          super(env)
        end
      end
      
      private
      
      def channel
        Pubs.channels[current_user.organisation_id]
      end
      
      def defer &blok

        action = proc {
          sleep(1) if Pubs.env.development?
          yield
        }
    
        callback = proc { |result|
          result
        }

        EM.defer action, callback

        json! 200, {}, true
        
      end
      
      def push! msg
        channel << Oj.dump(msg)
      end
      
    end
  end
end
