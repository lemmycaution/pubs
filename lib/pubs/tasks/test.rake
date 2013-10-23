desc "test[file] with minitest"
task :test,[:file] do |t,args|
  
  begin
    require "config/application"
  rescue Exception => e
    nil
  end
  
  require 'pubs/config'
  
  Pubs.env = "test"
  
  Pubs.load_env_vars
  
  # include support files
  Dir.glob('spec/support/*.rb') { |f| require f }
  
  # Run them all or only one
  if args[:file].nil?
    Dir.glob('spec/**/*_spec.rb') { |f| require f }
  else
    require "spec/#{args[:file]}_spec.rb"
  end

end

task default: :test
