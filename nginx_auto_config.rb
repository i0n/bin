def nginx_auto_config(source_file, target_file, app_name)
  nginx_config = IO.readlines(target_file)
  nginx_last_line = nginx_config.pop
  source_config = IO.read(source_file)
  nginx_config.push source_config
  nginx_config.push nginx_last_line
  nginx_config.each {|line| line.gsub!(/\#\{app_name\}/, "#{app_name}")}
  File.open(target_file, "w") do |file|
    file.puts nginx_config
  end  
end