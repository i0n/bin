def nginx_auto_config(source_file, target_file, app_name)
  nginx_config = IO.readlines(target_file)
  nginx_config.delete_if do |line|
    line == "\n" || line == ""
  end
  nginx_config.reverse_each do |line|
    if line == "}\n" || line == "}" && @nginx_last_line == nil
      @nginx_last_line = nginx_config.slice!(nginx_config.find_index(line))
    end
  end
  source_config = IO.read(source_file)
  nginx_config.push source_config
  nginx_config.push @nginx_last_line
  nginx_config.each {|line| line.gsub!(/\#\{app_name\}/, "#{app_name}")}
  File.open(target_file, "w") do |file|
    file.puts nginx_config
  end
  puts "Success! Nginx config for #{app_name} has been added to #{target_file}"
  puts
  puts "******************************************************************************************************************************************"
  puts
end