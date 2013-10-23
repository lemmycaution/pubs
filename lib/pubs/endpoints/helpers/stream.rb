require 'oj'

module Pubs
  module Endpoints
    module Stream
      
      STATUSES = {
        keepalive: Oj.dump({status: 0}),
        closed: Oj.dump({status: -1})
      }.freeze
  
      SERVER_TIME_OUT = 25
      
      def stream &blok
        
        keepalive = EM.add_periodic_timer(SERVER_TIME_OUT) do
          push STATUSES[:keepalive]
        end

        action = proc {
          sleep(1) if Pubs.env.development?
          yield
        }
    
        callback = proc { |result|
          keepalive.cancel          
          push result
          push STATUSES[:closed]
          env.stream_close
        }

        EM.defer action, callback

        halt! [200, {'Content-Type' => 'application/json'}, Goliath::Response::STREAMING]
        
      end
      
      def push msg
        env.stream_send "#{msg}\n"
      end
      
    end
  end
end