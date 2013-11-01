require 'pubs/clients/constants'
require 'goliath/rack'
require 'base64'
require 'aescrypt'
require 'bcrypt'
module Goliath
  module Contrib
    module Rack


      class CorsAccessControl

        include Pubs::Clients::Constants

        include Goliath::Rack::AsyncMiddleware

        DEFAULT_CORS_HEADERS = {
          'Access-Control-Allow-Origin'   => '*',
          'Access-Control-Expose-Headers' => 'X-CSRF-Token,X-Sid',
          'Access-Control-Max-Age'        => '0',
          'Access-Control-Allow-Methods'  => 'POST, GET, OPTIONS',
          'Access-Control-Allow-Headers'  => 'Content-Type,X-CSRF-Token,X-Sid'
          # 'Access-Control-Allow-Credentials' => 'true'
        }.freeze

        def call(env, *args)

          # XHR? what? piss off dude
          raise Goliath::Validation::UnauthorizedError if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"

          # Authenticate By Api Key if request not an CROS ajax
          if env[HTTP_ORIGIN].nil?
            raise Goliath::Validation::UnauthorizedError  unless http_auth_by_key!(env)
            super(env)

          else
            # By Outsiders
            raise Goliath::Validation::UnauthorizedError unless ENV[ORIGINS].include?( env[HTTP_ORIGIN] || "" )
          end

          # Check Access-Control Headers
          if env["REQUEST_METHOD"] == "OPTIONS"
            return [200, access_control_headers(env), []]
          end


          if ENV['CSRF'] == "true"
            if env["REQUEST_METHOD"] == GET and !env[HTTP_X_SID].nil?

              if Pubs.cache.get( AESCrypt.decrypt(env[HTTP_X_SID].gsub(/---/,"\n"), ENV['SECRET']) )
                token = SecureRandom.urlsafe_base64(nil, false)
                token = { 'X-CSRF-Token' => Pubs.cache.fetch(token,TTL){token} }
                return [200, access_control_headers(env).merge!(token), []]
              end

            elsif !Pubs.cache.delete(env["HTTP_X_CSRF_TOKEN"])

              raise Goliath::Validation::UnauthorizedError
            end
          end

          super(env)
        end

        def post_process(env, status, headers, body)

          unless env[HTTP_ORIGIN].nil?
            headers[ACCESS_CONTROL_ALLOW_ORIGIN] = '*'
            headers['Access-Control-Allow-Headers'] = 'X-Sid;X-CSRF-Token'
          end

          [status, headers, body]
        end

        private

        def access_control_headers(env)
          cors_headers = DEFAULT_CORS_HEADERS.dup
          client_headers_to_approve = env[HTTP_ACCESS_CONTROL_REQUEST_HEADERS].to_s.gsub(/[^\w\-\,]+/,'')
          cors_headers[ACCESS_CONTROL_ALLOW_HEADERS] += ",#{client_headers_to_approve}" if not client_headers_to_approve.empty?
          cors_headers
        end

        # Ensure Clients can have API KEY FROM Somewhere
        def http_auth_by_key!(env)
          raise Goliath::Validation::UnauthorizedError if env[HTTP_X_API_KEY].nil? or
          BCrypt::Password.new(env[HTTP_X_API_KEY]) != ENV[API_SECRET]
          true
        end


      end

    end
  end
end