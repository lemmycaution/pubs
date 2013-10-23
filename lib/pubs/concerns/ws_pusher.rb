require 'oj'
require 'active_support/concern'
require 'eventmachine'

module Pubs
  module Concerns
    module WSPusher
      extend ActiveSupport::Concern
  
      def push message
        if EventMachine.reactor_running?
          puts "streamer: #{message}"
          Pubs.channels[self.organisation_id] << Oj.dump({status: message})
        end
      end

    end
  end
end