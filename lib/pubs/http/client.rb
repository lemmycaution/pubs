require 'em-synchrony/em-http'

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
        return nil unless EventMachine.reactor_running?
        http = EM::HttpRequest.new(url).send method, params
        http.response
      end
    
    end
  end
end