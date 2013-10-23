require 'bcrypt'
require 'active_support/hash_with_indifferent_access'
require 'pubs/core_ext/kernel'
require 'pubs/heroku/command/fork'
require 'pubs/concerns/heroku_api'

module Pubs
  module Concerns
    module Forkable
  
      extend ActiveSupport::Concern

      included do
        
        # synchronous_commit = true
          
        [HerokuApi].each { |module_class|  
          include module_class unless included_modules.include? module_class 
        }
          
        store_accessor   :meta, :app
          
        after_initialize :ensure_mock_app, if: "Pubs.mock?"  
        before_create    :fork_app
        before_destroy   :destroy_app 
      end
        
      module ClassMethods
        def fork_from source
          @source_app = source
        end
        def source_app
          @source_app
        end
      end
      
      private
      
      def fork_app
        raise "No Source App Found" unless self.class.source_app
        begin
          self.app = begin 
            if Pubs.mock?
              heroku.post_app(name: mock_fork['name'], stack: 'cedar').body
              mock_fork
            else
              Heroku::Command::Fork.new(nil, {app: self.class.source_app}).index
            end
          end
          after_fork self.app
        rescue Exception => e
          puts "--> Error Forkable#fork_app #{e.inspect} #{e.try(:response).try(:body)}" 
          self.errors.add :app, e.inspect
          destroy_app
        end
      end
      
      def destroy_app
        heroku.delete_app(self.app['name']) rescue nil
      end
      
      def after_fork app
        self.domains << app['domain_name']['domain']
      end
      
      def mock_fork
        @mock_fork ||= Heroku::Command::Fork.new(nil, {app: self.class.source_app}).index.
        tap{ |mock| 
          mock["name"] = self.name.parameterize 
        }
      end
      
      def ensure_mock_app
        unless new_record?
          begin
            heroku.get_app(self.app["name"])
          rescue Exception => e
            if e.try(:response).try(:status) == 404
              heroku.post_app(name: mock_fork['name'], stack: 'cedar').body
            else 
              # raise e  
              puts "--> Error Forkable#ensure_mock_app #{e}"
            end
          end
        end
      end
  
    end

  end
end
