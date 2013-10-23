require 'yaml'
require 'active_support/concern'

module Pubs
  module Mock
    
    extend ActiveSupport::Concern
    
    module ClassMethods
      
      def mock what
        YAML.load(File.read("#{Pubs.root}/spec/mocks/#{what}.yml"))
      end
      
      def mock?
        !env.production?
      end
      
    end
  end
end

Pubs.send :include, Pubs::Mock