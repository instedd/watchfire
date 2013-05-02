require 'bundler/capistrano'
require 'rvm/capistrano'
require 'foreman/capistrano'

set :rvm_ruby_string, '1.9.3'
set :rvm_type, :system
set :sudo, 'rvmsudo'

set :application, "watchfire"
set :repository,  "https://bitbucket.org/instedd/watchfire"
set :scm, :mercurial
set :deploy_via, :remote_cache
set :user, 'ubuntu'

set :foreman_concurrency, 'scheduler=1'

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end

  task :symlink_configs, :roles => :app do
    %W(settings database).each do |file|
      run "ln -nfs #{shared_path}/#{file}.yml #{release_path}/config/"
    end
  end
end

namespace :foreman do
  desc 'Prepare foreman env file with current environment variables'
  task :set_env, :roles => :app do
    run "echo -e \"PATH=$PATH\\nGEM_HOME=$GEM_HOME\\nGEM_PATH=$GEM_PATH\\nRAILS_ENV=production\" >  #{current_path}/.env"
  end
end

before "deploy:start", "deploy:migrate"
before "deploy:restart", "deploy:migrate"
after "deploy:update_code", "deploy:symlink_configs"

before "foreman:export", "foreman:set_env"
after "deploy:update", "foreman:export"    # Export foreman scripts
after "deploy:restart", "foreman:restart"   # Restart application scripts
