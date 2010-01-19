################################################################### SET INSTALL VARIABLES & DEPENDENCIES #################################

# Get the name of the app
app_name = `pwd`.split('/').last.strip

# Get the name or IP of the remote server
puts "Enter the name or IP address of the remote server for this project"
remote_server = gets.chomp

# Sets the path to the rails-templates repository
rails_templates_path = '/Users/i0n/sites/bin/templates'
BIN_PATH = '/Users/i0n/sites/bin'

require "#{BIN_PATH}/nginx_auto_config.rb"

################################################################### METHODS #############################################

# Method for inserting a line after a specific line in a file. Note that this method will match only the first line it finds.
def append_after_line(target_file, target_line, new_line)
  file = IO.readlines(target_file)
  new_file = file.dup
  file.each do |line|
    if line.chomp == target_line.chomp && new_line != nil
      new_file.insert((file.find_index(line) + 1), new_line)
      new_line = nil
    end
  end
  File.open(target_file, "w") do |x|
    x.puts new_file
  end
end

# Method for appending text to the end of a file
def append_to_end_of_file(target_file,new_line,remove_last_line)
  file = IO.readlines(target_file)
  file.pop if remove_last_line == true
  file.push new_line
  File.open(target_file, "w") do |x|
    x.puts file
  end
end

################################################################### INSTALL PLUGINS #####################################

# Install Exception Notification plugin
plugin 'exception_notification', :git =>  'git://github.com/rails/exception_notification.git'
# Add recipiant email addresses to production.rb environment so that exception_notification plugin knows where to send exceptions
append_to_end_of_file('config/environments/production.rb', "# Config for email addresses to send exceptions to \nExceptionNotifier.exception_recipients = \%w(ianalexanderwood@gmail.com)", false)
# adds the include for exception_notifiable to application controller
append_after_line('app/controllers/application_controller.rb', 'class ApplicationController < ActionController::Base', '  include ExceptionNotifiable')

################################################################### INSTALL GEMS #####################################

# Setup RSpec to use gem(s)
run "echo '\nconfig.gem \"rspec\", :lib => false, :version => \">= 1.2.0\"\nconfig.gem \"rspec-rails\", :lib => false, :version => \">= 1.2.0\"'>>config/environments/test.rb"

# Install Haml/Sass and config Sass to compress generated stylesheets
run "haml --rails ."
run "echo '\n\nSass::Plugin.options[:style] = :compressed' >> config/environment.rb"

# Install Gems if they are not already on the local system
rake("gems:install", :sudo => true)

# Freeze Gems for upload
rake("rails:freeze:gems")
rake("gems:unpack")

################################################################### CREATE DATABASES AND RUN MIGRATIONS #####################################

# create databases
rake("db:create:all")

# Migrate database (included here in case of the adition of migrations at a later date)
rake("db:migrate")

# Generate rspec files
generate("rspec")
rake("spec")

################################################################### CREATE AND EDIT FILES ##################################################

# Create .gitignore
file ".gitignore" do
 IO.read("#{rails_templates_path}/base/.gitignore")
end

# Change Production environment config for use with remote server
append_to_end_of_file('config/database.yml', '  socket: /var/run/mysqld/mysqld.sock', true)

# config for local OSX Nginx environment
nginx_auto_config("#{rails_templates_path}/rails/config/nginx.local.conf", '/usr/local/nginx/conf/nginx.conf', "#{app_name}")

# Appending URI to /etc/hosts to complete local OSX Nginx config
run "sudo chmod 777 /etc/hosts"
run "echo '\n127.0.0.1 #{app_name}.local'>>/etc/hosts"

# Create HAML application layout
file 'app/views/layouts/application.html.haml' do
  IO.read("#{rails_templates_path}/rails/app/views/layouts/application.html.haml")
end

# Create stylesheets and sass directories and populate with standard stylesheet framework
Dir.mkdir 'public/stylesheets/sass'
file 'public/stylesheets/layout.css' do
  IO.read("#{rails_templates_path}/base/public/stylesheets/layout.css")
end
file 'public/stylesheets/sass/global.sass' do
  IO.read("#{rails_templates_path}/base/public/stylesheets/sass/global.sass")
end
file 'public/stylesheets/sass/ie.sass' do
  IO.read("#{rails_templates_path}/base/public/stylesheets/sass/ie.sass")
end
file 'public/stylesheets/sass/mobile.sass' do
  IO.read("#{rails_templates_path}/base/public/stylesheets/sass/mobile.sass")
end
file 'public/stylesheets/sass/print.sass' do
  IO.read("#{rails_templates_path}/base/public/stylesheets/sass/print.sass")
end
file 'public/stylesheets/sass/screen.sass' do
  IO.read("#{rails_templates_path}/base/public/stylesheets/sass/screen.sass")
end

# Create JQuery core file
file 'public/javascripts/jquery-1.3.2.min.js' do
  IO.read("#{rails_templates_path}/base/public/javascripts/jquery-1.3.2.min.js")
end
# Create JQuery document ready file
file 'public/javascripts/init.js' do
  IO.read("#{rails_templates_path}/base/public/javascripts/init.js")
end

# Set the logger for production environment to split log file on a daily basis
append_to_end_of_file('config/environments/production.rb', "# Config logger \nconfig.logger = Logger.new(config.log_path, 'daily')", false)

################################################################### CAPISTRANO CONFIGURATION #############################################################

# Set application up for deployment with Capistrano
capify!

# Read Capistrano template and replace remote_server and app_name variables with the values entered during app creation
cap_txt = IO.read("#{rails_templates_path}/rails/config/deploy.rb")
cap_txt.gsub!(/\#\{remote_server\}/, "#{remote_server}")
cap_txt.gsub!(/\#\{app_name\}/, "#{app_name}")
file 'config/deploy.rb' do
  cap_txt
end

################################################################### GIT CONFIGURATION #############################################################

# Initialise Git repository
git :init

# Add all changes to the Git repository and then commit those changes.
git :add => "."
git :commit => "-v -a -m 'Initial commit'"

################################################################### REMOTE DEPLOYMENT ##############################################################

# Ask about deploying to remote server
if yes?("Do you want to push this project to the remote server #{remote_server}?")
  puts "Deploying to: #{remote_server}"
  run "ssh #{remote_server} sudo git clone git://github.com/i0n/dotfiles.git /usr/local/bin/dotfiles" 
  run "ssh #{remote_server} sudo cp /usr/local/bin/dotfiles/make_git_repo /usr/local/bin/make_git_repo"
  run "ssh #{remote_server} sudo cp /usr/local/bin/dotfiles/nginx_auto_config /usr/local/bin/nginx_auto_config"
  run "ssh #{remote_server} sudo cp /usr/local/bin/dotfiles/nginx_auto_config.rb /usr/local/bin/nginx_auto_config.rb"
  run "ssh #{remote_server} sudo cp /usr/local/bin/dotfiles/templates/rails/config/nginx.remote.conf /usr/local/bin/nginx.remote.conf"
  run "ssh #{remote_server} sudo rm -rf /usr/local/bin/dotfiles"
  run "ssh #{remote_server} 'make_git_repo #{app_name}'"
  run "git remote add origin ssh://#{remote_server}/~/git/#{app_name}.git"
  run "git push origin master"
  run "cap deploy:setup"
  run "cap deploy:create_mysql_db"
  run "cap deploy:check"
  run "cap deploy:nginx"
  run "cap deploy:migrations"
end

puts "SUCCESS!"