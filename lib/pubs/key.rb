require 'openssl'
require 'active_support/concern'

module Pubs
  module Key
    
    extend ActiveSupport::Concern
        
    module ClassMethods
      def generate_key(salt = Time.now)
        OpenSSL::HMAC.hexdigest('sha1', salt.to_s, secret)
      end
    end
  end
end

Pubs.send :include, Pubs::Key