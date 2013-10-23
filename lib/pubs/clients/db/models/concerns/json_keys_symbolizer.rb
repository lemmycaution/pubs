require 'active_support/concern'
require 'active_support/core_ext/hash/keys'

module Concerns
  module JsonKeysSymbolizer
    extend ActiveSupport::Concern
    
    included do
      after_initialize :deep_symbolize_all_keys
      before_save :deep_transform_all_keys
    end
    
    module ClassMethods
      attr_reader :attrs_symbolize
      def attr_symbolize *args
        @attrs_symbolize = args 
      end
    end
    
    private

    def deep_symbolize_all_keys
      self.class.attrs_symbolize.each { |a| 
        self[a].deep_symbolize_keys! 
      }
    end
    
    def deep_transform_all_keys
      self.class.attrs_symbolize.each { |a| 
        self[a].deep_transform_keys! { |k| 
          k.to_s.parameterize.underscore.to_sym 
        } 
      }
    end
    
  end
end
