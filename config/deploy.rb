# config valid only for current version of Capistrano
lock '3.4.1'

set :application, 'watchfire'
set :repo_url, 'git@github.com:instedd/watchfire.git'

ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

set :deploy_to, "/u/apps/#{fetch(:application)}"
set :scm, :git
set :pty, true
set :keep_releases, 5
set :rails_env, :production
set :migration_role, :app

# Default value for :linked_files is []
set :linked_files, ['config/database.yml', 'config/settings.yml', 'config/newrelic.yml']

# Default value for linked_dirs is []
set :linked_dirs, ['log', 'tmp/pids', 'tmp/cache']

# Name for the exported service
set :service_name, fetch(:application)

namespace :service do
  task :export do
    on roles(:app) do
      opts = {
        app: fetch(:service_name),
        log: File.join(shared_path, 'log'),
        user: fetch(:deploy_user),
        concurrency: "puma=1,scheduler=1"
      }

      execute(:mkdir, "-p", opts[:log])

      within release_path do
        execute :sudo, '/usr/local/bin/bundle', 'exec', 'foreman', 'export',
                'upstart', '/etc/init', '-t', "etc/upstart",
                opts.map { |opt, value| "--#{opt}=\"#{value}\"" }.join(' ')
      end
    end
  end

  # Capture the environment variables for Foreman
  before :export, :set_env do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :bundle, :exec, "env | grep '^\\(PATH\\|GEM_PATH\\|GEM_HOME\\|RAILS_ENV\\|PUMA_OPTS\\INSTEDD_THEME\\)'", "> .env"
        end
      end
    end
  end

  task :safe_restart do
    on roles(:app) do
      execute "sudo stop #{fetch(:service_name)} ; sudo start #{fetch(:service_name)}"
    end
  end
end

namespace :deploy do
  after :updated, "service:export"         # Export foreman scripts
  after :restart, "service:safe_restart"   # Restart background services
end
