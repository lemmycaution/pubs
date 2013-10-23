require 'goliath/application'
require 'active_support/concern'
require "goliath/rack/templates"
require 'open-uri'

module Pubs
  module Endpoints
    module Helpers
      module Template
      
        extend ActiveSupport::Concern
            
        module Helpers
          
          private   
        
          def partial path, locals = {}
            self.send :erb, path, {layout: false, locals: locals}
          end
      
          def url_for(subdomain, path, params = nil)
            protocol = subdomain == "id" ? "https" : "http"
            query = params.nil? ? "" : "?#{params.to_query}"
            "#{protocol}://#{Pubs.subdomains.try(:[],subdomain)}/#{path}#{query}"
          end
      
          def asset_host
            @asset_host ||= Pubs.config(:haproxy)['asset_host']
          end
      
          def asset_path path
            "#{asset_host}#{path}"
          end
        
          def view! temp, locals = {}
            halt! [200, {"Content-Type" => "text/html"}, erb(temp, {locals: locals.update({template: temp})})]  
          end
        
          def error! status
            halt! [404,{}, open(asset_path("/errors/404.html")) ] if [404].include? status
            super
          end
        end
      
        include Helpers      
            
        included do
          include Goliath::Rack::Templates
        end
      
        def render(engine, data, options = {}, locals = {}, &block)
          super(engine,data,options,locals,&block)
        end
      
      end
    end
  end
end