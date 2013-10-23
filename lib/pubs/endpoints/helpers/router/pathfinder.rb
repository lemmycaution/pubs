module Pubs
  module Endpoints
    module Helpers
      module Router
        module Pathfinder
        
          RPRIA = /\/([a-zA-Z]+)\/([0-9]+)\/([a-zA-Z]+)\/([0-9]+)\/([a-zA-Z]+)/
          RPRI  = /\/([a-zA-Z]+)\/([0-9]+)\/([a-zA-Z]+)\/([0-9]+)/        
          RPRA  = /\/([a-zA-Z]+)\/([0-9]+)\/([a-zA-Z]+)\/([a-zA-Z]+)/        
          RPR   = /\/([a-zA-Z]+)\/([0-9]+)\/([a-zA-Z]+)/        
          RIA   = /\/([a-zA-Z]+)\/([0-9]+)\/([a-zA-Z]+)/        
          RI    = /\/([a-zA-Z]+)\/([0-9]+)/     
          RA    = /\/([a-zA-Z]+)\/([a-zA-Z]+)/        
          I     = /\/([0-9]+)/        
      
          private
      
          def detect_path(env)
            search_for_sub_resource(env) || search_for_resource(env)
          end
      
          def search_for_sub_resource env
        
            # /resource/:parent_id/resources/:id/:action
            if env["REQUEST_PATH"] =~ RPRIA
              parent_id = "#{$1}_id"
              path = "/#{$1}/:#{parent_id}/#{$3}/:id/#{$5}"
              params[parent_id] = $2                    
              params["id"] = $4
        
              # /resource/:parent_id/resources/:id
            elsif env["REQUEST_PATH"] =~ RPRI
              parent_id = "#{$1}_id"
              path = "/#{$1}/:#{parent_id}/#{$3}/:id"
              params[parent_id] = $2                    
              params["id"] = $4
        
              # /resource/:parent_id/resources/:action
            elsif env["REQUEST_PATH"] =~ RPRA
              parent_id = "#{$1}_id"
              path = "/#{$1}/:#{parent_id}/#{$3}/#{$4}"
              params[parent_id] = $2  
          
              # /resource/:parent_id/resources
            elsif env["REQUEST_PATH"] =~ RPR
              parent_id = "#{$1}_id"
              path = "/#{$1}/:#{parent_id}/#{$3}"
              params[parent_id] = $2 
          
            else
              path = nil
          
            end
        
            path
          end
      
          def search_for_resource env
        
            # /resources/:id/:action
            if env["REQUEST_PATH"] =~ RIA
              path = "/#{$1}/:id/#{$3}"
              params["id"] = $2
        
              # /resources/:id
            elsif env["REQUEST_PATH"] =~ RI
              path = "/#{$1}/:id"
              params["id"] = $2
        
              # /resources/:action
            elsif env["REQUEST_PATH"] =~ RA
              path = "/#{$1}/#{$2}"
        
              # /:id    
            elsif env["REQUEST_PATH"] =~ I
              path = "/:id"
              params["id"] = $1          
                
            else
              path = env["REQUEST_PATH"]   
          
            end
        
            path
          end
      
        end
      end
    end
  end
end