require 'pubs/concerns/forkable'

module Pubs
  module Concerns
    module Domains
  
      extend ActiveSupport::Concern

      included do
          
        [Forkable].each { |module_class|  
          include module_class unless included_modules.include? module_class 
        }
          
        validate         :check_domain_uniqueness  

        before_update    :delete_domains
        after_save       :set_domains
        before_destroy   :clear_domains
      end
      
      private
      
      def delete_domains 
        
        self.meta_was["domains"].each do |domain|
          if (domain = domain.strip).present?
            Pubs.cache.delete cache_key(domain)
            delete_domain domain
          end
        end
        
        self.domains = self.domains.map!(&:strip).uniq.compact

      end  
  
      def set_domains
        self.domains.uniq.compact.each do |domain|
          if (domain = domain.strip).present?
            Pubs.cache.set cache_key(domain), self.id
            post_domain domain
          end
        end
      end 
  
      def check_domain_uniqueness
        self.domains.each do |domain|
          if (id = Pubs.cache.get(domain)).present? && id != self.id
            if self.class.find_by(id: id)
              errors.add(:domains, :taken) 
            else
              Pubs.cache.delete cache_key(domain)
            end  
          end 
        end 
      end
      
      def clear_domains
        self.domains.each{|domain| Pubs.cache.delete cache_key(domain)}
      end
        
      def post_domain domain
        heroku.post_domain self.app['name'], domain rescue nil
      end
    
      def delete_domain domain
        heroku.delete_domain self.app['name'], domain rescue nil
      end
      
      def cache_key(domain)
        "sites:#{domain}"
      end

    end
  end
end
