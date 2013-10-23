require 'yaml'
require 'erb'
require 'pathname'
require "active_support/concern"
require "active_support/string_inquirer"
require "active_support/inflector"
require "pubs/core_ext/kernel"

module Pubs
  module Config
    
    EXE = "pubs.io"
    
    extend ActiveSupport::Concern
    
    module ClassMethods
      
      def config name
        name = "#{name}.yml" unless /\.yml/ =~ name
        var_name = "@#{name.parameterize.underscore}"
        unless config = instance_variable_get(var_name)
          config = instance_variable_set(var_name, 
          YAML.load(ERB.new(File.read("#{root}/config/#{name}")).result)[env]
          )
        end  
        config
      end
      
      def env env = nil
        if env and block_given?
          _env = @env
          self.env = env
          yield
          self.env = _env
        end
        @env ||= ActiveSupport::StringInquirer.new(ENV['RACK_ENV'] ||= 'development')
      end
  
      def env=(environment)
        @env = ENV['RACK_ENV'] = ActiveSupport::StringInquirer.new(environment)
      end
  
      def root
        @root ||= find_root_with_flag(EXE, Dir.pwd).to_s
      end
  
      def root= root
        @root = root
      end
      
      def path
        @path ||= File.expand_path('../../..', __FILE__)
      end
      
      def load_env_vars file = "#{root}/.env"
        unless File.exists?(file)
          puts "File not found for load_env_vars #{file}"
          return false
        end
        Hash[File.read(file).gsub("\n\n","\n").split("\n").compact.map{ |v| 
          v.split("=")
        }].each { |k,v| ENV[k] = v }
      end
      
      def inside_app?
        File.exist?("#{root}/#{Pubs::EXE}")
      end
      
      private
  
      # i steal this from rails
      def find_root_with_flag(flag, default=nil)
        root_path = self.class.called_from[0]

        while root_path && File.directory?(root_path) && !File.exist?("#{root_path}/#{flag}")
          parent = File.dirname(root_path)
          root_path = parent != root_path && parent
        end

        root = File.exist?("#{root_path}/#{flag}") ? root_path : default
        raise "Could not find root path for #{self}" unless root

        RbConfig::CONFIG['host_os'] =~ /mswin|mingw/ ?
        Pathname.new(root).expand_path : Pathname.new(root).realpath
      end
      
    end
    
  end
end

Pubs.send :include, Pubs::Config