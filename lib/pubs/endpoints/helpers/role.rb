require 'pubs/concerns/roles'
require 'active_support/string_inquirer'

module Pubs
  module Endpoints
    module Helpers
      module Role

        private

        def can? action, klass
          current_user.can? action, klass
        end

        def authenticate_user_roles! action = :manage, klass = model_class
          authenticate_user!
          unless can? action, klass
            if xhr?
              error! 401
            else
              redirect! url_for("id","")
            end
          end
        end

        def model_class
          self.class.name.gsub("Endpoint","").singularize
        end

      end
    end
  end
end