require 'active_support/concern'
require 'pubs/config'

module Pubs
  module Variables
    
    extend ActiveSupport::Concern
    
    module ClassMethods
      
      attr_accessor :secret, :domain, :subdomains

      %w(secret domain subdomains).each do |attr_name|
        class_eval <<-CODE
        def #{attr_name}
          @#{attr_name} ||= config("pubs.yml")['#{attr_name}']
        end
        CODE
      end
    end
  end
end

Pubs.send :include, Pubs::Variables