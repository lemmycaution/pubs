require 'pubs/http/client'

module Concerns
  
  module Hooks
      
    extend ActiveSupport::Concern
    
    included do
      after_create do  
        run_hooks(:after_create) if has_model?
      end
      after_update do
        run_hooks(:after_update) if has_model?
      end      
      after_destroy do
        run_hooks(:after_destroy) if has_model?
      end            
    end
    
    private
    
    def url_for(subdomain, path, params = nil)
      protocol = subdomain == "id" ? "https" : "http"
      query = params.nil? ? "" : "?#{params.to_query}"
      "#{protocol}://#{Pubs.subdomains.try(:[],subdomain)}/#{path}#{query}"
    end
    

    
    def run_hooks(callback)
      if hooks = self.model.hooks[callback]
        hooks.each do |api, actions|
          run_hook callback, api, actions
        end
      end
    end
    
    def run_hook callback, api, actions
      
      Pubs::HTTP::Client.new.post( hook_api_url(api), {
        head: {
          "X-Api-Key" => hook_api_key(api)
        }, 
        body: {
          callback: callback,
          method: name,
          actions: actions,
          unit: self.as_json
        }
      })
      
    end
    
    def hook_api_url(api)
      self.model.hooks.try(:[],:apis).try(:[],api).try(:[],:url)
    end
    
    def hook_api_key(api)
      self.model.hooks.try(:[],:apis).try(:[],api).try(:[],:key)
    end
            
  end
end

