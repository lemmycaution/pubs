require 'active_support/concern'
require 'pubs/endpoints/helpers/router/pathfinder'

module Pubs
  module Endpoints
    module Helpers
      module Router

        extend ActiveSupport::Concern

        include Pathfinder

        module ClassMethods

          def routes
            @routes ||= {}
          end

          def get(route, &block)
            register_route('GET', route, &block)
            register_route('HEAD', route, &block)
          end

          def post(route, &block)
            register_route('POST', route, &block)
          end

          def put(route, &block)
            register_route('PUT', route, &block)
          end

          def patch(route, &block)
            register_route('PATCH', route, &block)
          end

          def delete(route, &block)
            register_route('DELETE', route, &block)
          end

          def head(route, &block)
            register_route('HEAD', route, &block)
          end

          def register_route(method, route, &block)
            self.routes[self.signature(method, route)] = block
          end

          def signature(method, route)
            "#{method}#{route}"
          end

        end

        def env
          @env
        end

        def response(env)

          @env = env

          # match route by parsed request
          unless block = get_block

            path = search_for_sub_resource(env)
            unless block = get_block(path)

              path = search_for_resource(env)
              block = get_block(path)
            end

          end

          ap path
          ap self

          catch :halt do |response|
            # run if there is a api for it
            if block
              instance_exec(&block)
            else
              error! 404
            end

            response
          end

        end

        private

        def halt!(response)
          throw :halt, response
        end

        def redirect! location
          halt! [302, {"Location" => location}, nil]
        end

        def json! status, header, body
          halt! [status, header.merge!({"Content-Type" => "application/json"}),
            (body.is_a?(String) ? body : body.try(:to_json))]
        end

        def error!(status)
          status! status
        end

        def status!(status)
          halt! [status, {}, nil]
        end

        def only_ajax! location = "/"
          redirect! location unless xhr?
        end

        def xhr?
          env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest" || internal?
        end

        def internal?
          env["HTTP_USER_AGENT"  ] == "Pubs::HTTP::InterClient"
        end

        def permitted_params permit = []
          params.keep_if{|key,val| permit.include? key}
        end

        def get_block(path = env["REQUEST_PATH"], method = env["REQUEST_METHOD"])
          self.class.routes[self.class.signature(method, path)]
        end

      end
    end
  end
end