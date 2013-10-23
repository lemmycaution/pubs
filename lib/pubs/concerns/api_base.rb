require 'pubs/concerns/forkable'
require 'pubs/concerns/scalable'
require 'pubs/concerns/addons'
require 'pubs/concerns/ws_pusher'

require 'bcrypt'

module Pubs
  module Concerns
    class ApiBase < ActiveRecord::Base  
      
      self.abstract_class = true
    
      [Forkable,Scalable,Addons,WSPusher].each { |module_class|  
        include module_class unless included_modules.include? module_class 
      }

      after_initialize :set_defaults
      after_create :configure!
      before_update :stash_configuration_changes
      after_update :reconfigure!

      store_accessor :meta, :logs, :domains, :origins, :api_key, :api_secret 

      validate :addons_validation
      validates_presence_of :name, :organisation_id, :api_key, :api_secret
      validates_uniqueness_of :name, scope: :organisation_id  

      attr_accessor :changed_configurations
      attr_writer   :reset_api_secret

      
      def reset_api_secret= confirm
        if confirm == self.api_secret
          self.api_secret = Pubs.generate_key
          self.api_key    = BCrypt::Password.create(self.api_secret)
        end
      end
  
      def as_json(options = {})
        defaults = {methods:[:price,:plan,:origins,:domains,:dynos], except: [:meta,:addons,:api_key,:api_secret]}
        super(defaults.merge(options){ |key,oldval,newval| oldval | newval })
      end
      
      def dynos
        return 1 if Pubs.mock? 
        super
      end
      
      private
  
      def set_defaults
        self.domains ||= []
        self.origins ||= []
        self.logs ||= []
        self.changed_configurations = {}
        self.api_secret ||= Pubs.generate_key
        self.api_key ||= BCrypt::Password.create(self.api_secret)
      end
  
      def after_fetch_addon addon
        if addon['name'] == "heroku-postgresql"
          attachment_name = addon['message'].match(/HEROKU_POSTGRESQL_(.*)_URL/).try(:captures).try(:[],0)
          url = heroku.get_config_vars(self.app['name']).body["HEROKU_POSTGRESQL_#{attachment_name}_URL"] 
          self.addons[addon['name']].update(
          {
            'attachment_name' => "HEROKU_POSTGRESQL_#{attachment_name}",
            'url' => Pubs.mock? ? "postgres://localhost/pubs_db_development" : url
          }
          )
          
          migrate! if !self.addons_was.empty? and heroku.get_config_vars(self.app['name']).body["DATABASE_URL"] != url
      
          clean!
        end
      end
  
      def migrate!
        push "Migrating..."        
        return if Pubs.mock? 
    
    
        from = self.addons_was['heroku-postgresql'].dup.tap{|a| a['name'] = "#{a['name']}:#{a['plan']}"}
        to = self.addons['heroku-postgresql'].dup.tap{|a| a['name'] = "#{a['name']}:#{a['plan']}"}    
    
        if is_production_db?
          waiting = Heroku::Command::Fork.new(nil, {app: self.app['name']}).
          send(:wait_for_db, self.app['name'], to)
          log!({"heroku-postgresql-waiting" => waiting})
        end
    
        transfer = Heroku::Command::Fork.new(nil, {app: self.app['name']}).
        send(:migrate_db, from, self.app['name'], to, self.app['name'])
        log!({"heroku-postgresql-migration" => transfer})
      end
  
      def clean!
        push "Cleaning..."
        addons = heroku.get_addons(self.app['name']).body
        addons.each do |_addon|
          if _addon["name"] =~ /^heroku-postgresql:/ 
            if _addon["attachment_name"] != self.addons["heroku-postgresql"]['attachment_name']
              push "Deleting #{_addon["attachment_name"]}"
              begin
                heroku.delete_addon(self.app['name'], _addon["attachment_name"])
              rescue Exception => e
                ap e.try(:response).try(:body)
                raise e unless Pubs.mock? 
              end
            end
          end
        end  
      end

      def configure!
        push "Configuring..."
        heroku.put_config_vars( self.app['name'], 
        {
          "API_SECRET" => self.api_secret,
          "DOMAIN" => self.app['domain_name']['domain'],      
          "ORIGINS" => self.origins.join(","),
          "SID" => self.app['name'],
          "SECRET" => Pubs.secret,      
          "DATABASE_URL" => self.addons["heroku-postgresql"]['url'],
          "PLV8" => "#{is_production_db?}"
        }
        )
        migrate_database!
      end
  
      def migrate_database!
        return if Pubs.mock?
        push "Running Migrations..."
        migration = heroku.post_ps(self.app['name'], 'rake db:migrate').body
        sleep(5)    
        log!({"rake-db-migrate" => migration})
      end
  
      def stash_configuration_changes
        if self.meta["api_secret"] != self.meta_was["api_secret"]
          changed_configurations["API_SECRET"] = self.api_secret
        end
        if self.meta["origins"] != self.meta_was["origins"]
          changed_configurations["ORIGINS"] = self.origins.join(",")
        end    
        if self.addons["heroku-postgresql"]["url"] != self.addons_was["heroku-postgresql"]["url"]
          changed_configurations["DATABASE_URL"] = self.addons["heroku-postgresql"]["url"]
        end        
        if self.addons["heroku-postgresql"]["plan"] != self.addons_was["heroku-postgresql"]["plan"]
          changed_configurations["PLV8"] = "#{is_production_db?}"
        end 
        ap "Stashed changes #{changed_configurations.inspect}"
      end
  
      def reconfigure!
        push "Re-Configuring..."
        ap changed_configurations
        begin
          heroku.put_config_vars( self.app['name'], changed_configurations)
        rescue Exception => e
          ap e.try(:response).try(:body)
          raise e
        end
        if changed_configurations.keys.include? "DATABASE_URL"
          migrate_database!
        end
        self.changed_configurations = {}
      end

      def log! val
        ap "log: #{val}"
        self.logs.pop if self.logs.length > 10
        self.logs.unshift val
      end
      
      def addons_validation
        addons.each do |key,addon|
          errors.add :addons, "Invalid Addon" unless self.class.addons.map{|k,a| a["name"] }.include? "#{addon["name"]}:#{addon["plan"]}"
        end
      end
      
      def is_production_db?
        !%w(dev basic).include?(self.addons["heroku-postgresql"]['plan'])
      end
      
    end
  end
end