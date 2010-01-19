set :application, "#{app_name}"
set :domain, "#{remote_server}"
set :user, 'i0n'

set :repository,  "#{user}@#{domain}:/home/#{user}/git/#{application}.git"

#default_environment['PATH']='/usr/local/bin /usr/local/sbin /usr/local/mysql/bin /usr/local/bin /usr/local/sbin /usr/local/mysql/bin /usr/local/bin /usr/local/sbin /usr/local/mysql/bin /usr/local/bin /usr/local/sbin /usr/local/mysql/bin /usr/local/bin /usr/local/sbin /usr/local/mysql/bin /usr/local/bin /usr/local/sbin /usr/local/mysql/bin /usr/local/bin /usr/local/sbin /usr/local/mysql/bin /usr/bin /bin /usr/sbin /sbin /usr/local/bin /usr/local/git/bin /usr/X11/bin /Users/i0n/sites/bin /Users/i0n/sites/bin /Users/i0n/sites/bin /Users/i0n/sites/bin /Users/i0n/sites/bin /Users/i0n/sites/bin /Users/i0n/sites/bin'
#default_environment['GEM_PATH']='/usr/lib/ruby/gems/1.8'

role :app, domain                           # This may be the same as the `Web` server
role :web, domain                           # Your HTTP server, Apache/etc
role :db,  domain , :primary => true        # This is where Rails migrations will run

set :scm_verbose, true

set :scm, :git
set :scm_username, user
set :runner, user
set :use_sudo, false
set :branch, "master"
set :deploy_via, :checkout
set :git_shallow_clone, 1
set :deploy_to, "/home/#{user}/sites/#{application}"
default_run_options[:pty] = true

namespace :deploy do
  #task which causes Passenger to initiate a restart
  task  :restart do
    run "mkdir -p #{release_path}/tmp && touch #{release_path}/tmp/restart.txt"
  end
  
  task :install_gems do
    run "cd #{current_path}; rake gems:install"
  end
  
  task :create_mysql_db do
    run "mysqladmin -u root create #{application}_production"
  end
  
  #Task to set up the remote Nginx server for app deployment
  task :nginx do
    run "#{sudo} nginx_auto_config '/usr/local/bin/nginx.remote.conf', '/opt/nginx/conf/nginx.conf' "
  end
end

after 'deploy:symlink', 'deploy:install_gems'

# Reminder of default actions for cap deploy:
# deploy:update_code
# deploy:symlink
# deploy:restart