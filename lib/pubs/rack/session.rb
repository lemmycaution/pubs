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
      SID                   = 'pubs.sid'
      TTL                   = 4800
      
      module Helper
        
        def force_session!(_env)
          cookie = ::Rack::Utils.parse_query(_env["HTTP_COOKIE"])
          env[ENV_SESSION_KEY] = Oj.load(Pubs.cache.get("sessions:#{cookie[SID]}") || "")
        end
        
        def session
          env[ENV_SESSION_KEY] || {}
        end
      
        def current_user
          if session["sid"].present? && session_user = Pubs.cache.get(session["sid"])
            Oj.load(session_user)
          end
        end

        def sign_in! user
          user.reset_sid! unless user.sid.present?
          session["sid"] = user.sid          
          Pubs.cache.set user.sid, user.to_json( methods: [:organisation] ), TTL
        end

        def sign_out!
          if session["sid"]
            Pubs.cache.delete session["sid"]
            session["sid"] = nil          
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
          session = Pubs.cache.get(cache_session_key)
          env[ENV_SESSION_KEY] = session ? Oj.load( session ) : {}
        end
    
        def set_session
          session_data = env[ENV_SESSION_KEY].delete_if{ |k, v| v.nil? }
          if session_data.empty?
            Pubs.cache.delete cache_session_key
            ::Rack::Utils.delete_cookie_header!(headers, SID, {
              value: session_key, path: "/", domain: domain
            }) 
          else
            Pubs.cache.set cache_session_key, Oj.dump( session_data ), TTL
            ::Rack::Utils.set_cookie_header!(headers, SID, {
              value: session_key, path: "/", domain: domain
            })
          end
        end
    
        def cache_session_key
          "sessions:#{session_key}"
        end
    
        def session_key
          cookie = ::Rack::Utils.parse_query(env[HTTP_COOKIE])
          cookie[SID].present? ? cookie[SID] : Pubs.generate_key
        end

      end 
    end
  end
