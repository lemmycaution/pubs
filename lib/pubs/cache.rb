require 'dalli'
require "singleton"
require 'active_support/concern'
require 'active_support/core_ext/hash/keys'
require 'pubs/config'

module Pubs
  module Cache
      
    extend ActiveSupport::Concern
      
    module ClassMethods
        
      def cache
        Pubs::Cache::Client.instance
      end
        
    end
    
    class Client
      
      include Singleton
    
      def self.instance
        return @instance if @instance
        config = Pubs.config(:cache).symbolize_keys
        @instance = Dalli::Client.new config.delete(:servers).split(","), config
      end
      
    end
      
  end
    
end

Pubs.send :include, Pubs::Cache