require 'em/channel'

module Pubs
  module Channels

    class ChannelPool

      def initialize
        @pool = {}
      end

      def []key
        @pool[key] ||= EM::Channel.new
      end

    end

    extend ActiveSupport::Concern

    module ClassMethods

      def channels
        @channels ||= ChannelPool.new
      end

    end

  end
end

Pubs.send :include, Pubs::Channels