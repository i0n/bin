def nginx_auto_config(source_file, target_file, app_name)
  if source_file == nil || target_file == nil || app_name == nil
    puts
    puts "******************************************************************************************************************************************"
    puts
    puts "You need to specify three paramters to use this script:\n\n1: The Source File.\n2: The Target File.\n3: The App Name."
    puts
    puts "e.g. nginx_auto_config /Users/i0n/Sites/bin/templates/rails/config/nginx.local.conf /usr/local/nginx/conf/nginx.conf test_app"
    puts
    puts "******************************************************************************************************************************************"
    puts
    exit
  else
    puts
    puts "******************************************************************************************************************************************"
    puts
    puts "Setting permissions for: #{target_file}"
    puts
    `sudo chmod 755 #{target_file}`
    nginx_config = IO.readlines(target_file)
    nginx_config.delete_if do |line|
      line == "\n" || line == ""
    end
    nginx_config.reverse_each do |line|      
      if line =~ /^\}[\n]*/
        @nginx_last_line = nginx_config.slice!(nginx_config.find_index(line))
        break
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
end