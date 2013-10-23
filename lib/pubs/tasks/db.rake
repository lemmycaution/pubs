require 'erb'
require 'active_record'
require 'yaml'

namespace :db do
  
  desc "erases and rewinds all dbs"
  task :reset do
    %w(development test).each do |env|
      ENV['RACK_ENV']=env
      Rake::Task["db:drop"].reenable      
      Rake::Task["db:create"].reenable
      Rake::Task["db:migrate"].reenable      
      Rake::Task["db:drop"].invoke      
      Rake::Task["db:create"].invoke
      Rake::Task["db:migrate"].invoke
    end
  end
  
  desc "loads database configuration in for other tasks to run"
  task :load_config do
    ActiveRecord::Base.configurations = db_conf
    
    # drop and create need to be performed with a connection to the 'postgres' (system) database
    ActiveRecord::Base.establish_connection db_conf.merge('database' => 'postgres',
                                                               'schema_search_path' => 'public')
  end
  
  desc "creates and migrates your database"
  task :setup => :load_config do
    Rake::Task["db:create"].invoke
    Rake::Task["db:migrate"].invoke
  end
  
  desc "migrate your database"
  task :migrate do
    ActiveRecord::Base.establish_connection db_conf

    ActiveRecord::Migrator.migrate(
      ActiveRecord::Migrator.migrations_paths, 
      ENV["VERSION"] ? ENV["VERSION"].to_i : nil
    )
  end
  
  desc 'Drops the database'
  task :drop => :load_config do
    ActiveRecord::Base.connection.drop_database db_conf['database']
  end
  
  desc 'Creates the database'
  task :create => :load_config do
    ActiveRecord::Base.connection.create_database db_conf['database']
  end
  
  
  def db_conf
    config = YAML.load(ERB.new(File.read('config/database.yml')).result)[env]
  end

  def env
    ENV['RACK_ENV'] || "development"
  end
  
end
