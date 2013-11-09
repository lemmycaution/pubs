require 'em-synchrony/em-http'
require 'httparty'

module Pubs
  module HTTP
    class Client

      %w(post get put patch delete).each do |method|
        class_eval <<-CODE
        def #{method} url, params = {}
          request :#{method}, url, params
        end
        CODE
      end

      def request method, url, params = {}
        unless EventMachine.reactor_running?
          http = HTTParty.send(method, url, params.symbolize_keys.tap{|p| p[:headers] = p.delete(:head)})
        else
          http = EM::HttpRequest.new(url).send method, params
        end
        # http.response
      end

    end
  end
end