require 'erb'
require 'yaml'
require 'active_record'
require 'active_support/concern'
require 'pubs/config'
require 'surus'

module Pubs
  module DB

    extend ActiveSupport::Concern
    
    include Pubs::Config
    
    module ClassMethods
    
      def db
        if env.production?
          URI.parse(ENV['DATABASE_URL']) 
        else  
          # YAML.load(ERB.new(File.read('config/database.yml')).result)[env]
          Pubs.config(:database)
        end
      end
  
      def establish_connection
        if env.production?       
          ActiveRecord::Base.establish_connection(
          adapter:      'postgresql',
          host:         db.host,
          username:     db.user,
          port:         db.port,
          password:     db.password,
          database:     db.path[1..-1],
          encoding:     'utf8',
          pool:         ENV['DB_POOL'] || 5,
          connections:  ENV['DB_CONNECTIONS'] || 20,
          reaping_frequency: ENV['DB_REAP_FREQ'] || 10
          )
        else # local environment
          ActiveRecord::Base.establish_connection(db)
        end
        ActiveRecord::Base.synchronous_commit = false        
      end
    
    end
    
  end
end

Pubs.send :include, Pubs::DB