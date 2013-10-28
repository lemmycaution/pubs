require 'goliath/api'
require 'goliath/websocket'
require 'pubs/endpoints/helpers/router'
require 'pubs/rack/session'
require 'pubs/channels'
module Pubs
  module Endpoints
    class WebSocket < Goliath::WebSocket

      STATUSES = {
        keepalive: {status: 0},
        closed: {status: -1}
      }.freeze

      SERVER_TIME_OUT = 25

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
        @env = env
        force_session!(env)
        return unless current_user
        env.logger.info("WS OPEN #{env['HTTP_SEC_WEBSOCKET_KEY']}")
        env['subscription'] = channel.subscribe { |m|

          force_session!(env)
          unless current_user
            env.logger.warn "NO USER FOUND !!!"
          end

          env.stream_send(m)
        }
      end

      def on_message(env, msg)
        @env = env
        force_session!(env)
        unless current_user
          env.logger.warn "NO USER FOUND !!!"
        end
        env.logger.info("WS MESSAGE #{env['HTTP_SEC_WEBSOCKET_KEY']}")
        push! msg
      end

      def on_close(env)
        @env = env
        return if env['subscription'].nil?
        env.logger.info("WS CLOSED #{env['HTTP_SEC_WEBSOCKET_KEY']}")
        channel.unsubscribe(env['subscription'])
      end

      def on_error(env, error)
        @env = env
        env.logger.error error
      end

      def on_body(env, data)
        @env = env
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


      # first part creating organisation scope for channels
      # then path based lazy exchanges
      def channel
        exchange = env["REQUEST_PATH"].gsub(/\/ws/,"").underscore
        Pubs.channels["#{current_user.organisation_id}_#{exchange}"]
      end

      def defer &blok

        keepalive = EM.add_periodic_timer(SERVER_TIME_OUT) do
          push! STATUSES[:keepalive]
        end

        action = proc {
          sleep(1) if Pubs.env.development?
          yield
        }

        callback = proc { |result|
          #keepalive.cancel
          result
        }

        EM.defer action, callback

        json! 200, {}, true

      end

      def push! msg
        msg = Oj.dump(msg) unless msg.is_a?(String)
        ap channel
        ap msg
        channel.push(msg)
      end

    end
  end
end
