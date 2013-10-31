require 'pubs/http/client'

module Pubs
  module HTTP

    class InterClient < Client

      def initialize(cookie = "", api_key = "")
        @head = {
          'user-agent' => self.class.name,
          'cookie' => cookie,
          'X-Api-Key' => api_key
        }
      end

      def request method, url, params = {}
        params.update({head: @head})
        http = EM::HttpRequest.new(url).send method, params
        http.response
      end

    end

  end
end