require "oj"
require 'goliath/rack/simple_aroundware'
require "pubs/variables"
require 'active_support/core_ext/object/try'
require 'active_support/core_ext/object/blank'

module Pubs
  module Rack
    class Session

      include Goliath::Rack::SimpleAroundware

      HTTP_COOKIE           = 'HTTP_COOKIE'
      ENV_SESSION_KEY       = 'rack.session'
      SID                   = 'pubs-io'
      TTL                   = 4800

      module Helper

        def force_session!(_env)
          # cookie = ::Rack::Utils.parse_query(_env[HTTP_COOKIE])
          # env[ENV_SESSION_KEY] = Oj.load(Pubs.cache.get("sessions:#{cookie[_env['SID']]}") || "")
        end

        def session
          env[ENV_SESSION_KEY] || {}
        end

        def current_user
          @user ||= begin
            if session["sid"].present? && session_user_id = Pubs.cache.get(session["sid"])
              User.unscoped.find_by(id: session_user_id.to_i)
            end
          end
        end

        def sign_in! user
          user.reset_sid! unless user.sid.present?
          session["sid"] = user.sid
          Pubs.cache.set user.sid, user.id, TTL
        end

        def sign_out!
          if session["sid"]
            Pubs.cache.delete session["sid"]
            session["sid"] = nil
            @current_user = nil
          end
        end

        def authenticate_user!
          unless current_user
            if xhr?
              error! 401
            else
              redirect! url_for("id","login")
            end
          end
        end

      end

      def initialize(env, sid = SID)
        env['SID'] = sid
        super(env)
      end


      def pre_process
        get_session
        return Goliath::Connection::AsyncResponse
      end

      def post_process
        set_session
        # headers = (headers || {}).merge({'Set-Cookie' => ["#{SID}=#{session_key};"]})
        # Rack::Utils.set_cookie_header!(headers, SID, {value: session_key, path: "/", domain: Pubs.domain})

          [status, headers, body]
        end

        private

        def domain
          Pubs.try(:domain) rescue nil
        end

        def get_session
          _session = Pubs.cache.get(cache_session_key)
          env[ENV_SESSION_KEY] = _session ? Oj.load( _session ) : {}
        end

        def set_session
          if env[ENV_SESSION_KEY]
            session_data = env[ENV_SESSION_KEY].delete_if{ |k, v| v.nil? }
            # if session_data.empty?
            #   Pubs.cache.delete cache_session_key
            #   ::Rack::Utils.delete_cookie_header!(headers, @sid, {
            #     value: session_key, path: "/", domain: domain
            #   })
            # else
            Pubs.cache.set cache_session_key, Oj.dump( session_data ), TTL
            ::Rack::Utils.set_cookie_header!(headers, env['SID'], {
              value: session_key, path: "/", domain: domain
            })
          # end
          end
        end

        def cache_session_key
          "#{env['SID']}:sessions:#{session_key}"
        end

        def session_key
          cookie = ::Rack::Utils.parse_query(env[HTTP_COOKIE])
          cookie[env['SID']].present? ? cookie[env['SID']] : Pubs.generate_key
        end

      end
    end
  end
