set :application, ""
set :domain, ""
set :user, 'i0n'

set :repository,  "#{user}@#{domain}:/home/#{user}/git/#{application}.git"

role :app, domain                           # This may be the same as the `Web` server
role :web, domain                           # Your HTTP server, Apache/etc
role :db,  domain , :primary => true        # This is where Rails migrations will run

set :scm_verbose, false

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
  
  desc "Restart Passenger"
  task  :restart do
    run "mkdir -p #{release_path}/tmp && touch #{release_path}/tmp/restart.txt"
  end
      
  desc "Set up the remote Nginx server for app deployment"
  task :nginx do
    run "#{sudo} nginx_auto_config /usr/local/bin/nginx.remote.conf /opt/nginx/conf/nginx.conf "
  end
    
end

# Reminder of default actions for cap deploy:
# deploy:update_code
# deploy:symlink
# deploy:restart