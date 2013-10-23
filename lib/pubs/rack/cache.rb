# Very Simple Middleware to deal with ETag & If-None_Match Headers
 
require "goliath/rack/async_middleware"

module Pubs
  module Rack
    class Cache
  
      include Goliath::Rack::AsyncMiddleware
  
      def post_process(env, status, headers, body)
        if body.is_a? String
          # Generate ETag for body
          etag = etag_for(body)
        
          # Add ETag header
          headers['ETag'] = etag
        
          # Response with status 304 without body
          if env['HTTP_IF_NONE_MATCH'] == etag
            status = 304
            body = nil
          end
        end
        [status,headers,body]
      end
      
      private
      
      # Generates ETag for given string
      def etag_for content
        Digest::MD5.hexdigest(content)
      end
      
    end
  end
end
