require 'oj'
require 'active_support/concern'
require 'eventmachine'

module Pubs
  module Concerns
    module WSPusher
      extend ActiveSupport::Concern

      def push message
        if EventMachine.reactor_running?
          puts "ws_pusher: #{message}"
          Pubs.channels[channel_id] << Oj.dump({status: message})
        end
      end

      def channel_id
        @channel_id ||= "#{self.organisation_id}/#{self.class.table_name}"
      end

    end
  end
end