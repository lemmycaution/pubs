require 'em/queue'

module Pubs
  module Queues
    
    class QueuePool
      
      def initialize
        @pool = {}
      end
      
      def []key 
        @pool[key] ||= EM::Queue.new
      end
      
    end
      
    extend ActiveSupport::Concern
    
    module ClassMethods
      
      def queues
        @queues ||= QueuePool.new
      end
      
    end
    
  end
end

Pubs.send :include, Pubs::Queues