Pubs.load_env_vars

namespace :assets do
  
  desc "compiles assets for production"
  task :compile do
    #app assets
    system "bundle exec coffee --map --compile --output #{app_script_path} app/assets/scripts"
    system "bundle exec sass --style compact --load-path #{lib_style_path} --force --update app/assets/styles:#{app_style_path}"
    #statics
    system "bundle exec coffee --map --compile --output #{static_script_path} #{lib_script_path}"    
    system "bundle exec sass --style compact --force --update #{lib_style_path}:#{static_style_path}"
  end
  
  desc "syncs assets with CDN"
  task :sync do
    Dir.chdir "#{pubs_io_root}/static" do
      system "ruby sync.rb"
    end
  end
  
  def app_name
    File.basename(File.expand_path("."))
  end

  def pubs_io_root
    
    ENV['PUBS_ROOT']
  end

  def app_script_path
    "#{pubs_io_root}/static/#{app_name}/scripts"
  end

  def lib_script_path
    "#{pubs_io_root}/static/lib/scripts"
  end

  def static_script_path
    "#{pubs_io_root}/static/scripts"
  end

  def app_style_path
    "#{pubs_io_root}/static/#{app_name}/styles"
  end

  def lib_style_path
    "#{pubs_io_root}/static/lib/styles"
  end

  def static_style_path
    "#{pubs_io_root}/static/styles"
  end
  
end

