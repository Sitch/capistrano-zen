require 'yaml'
DB_FILE_PATH = "#{app_root_path}/config/database.yml"
dbconfig = YAML.load_file(DB_FILE_PATH)

_cset(:postgresql_host, "localhost")
_cset(:postgresql_user) { dbconfig['production']['username'] }
_cset(:postgresql_password) { dbconfig['production']['password'] }
_cset(:postgresql_database) { dbconfig['production']['database'] }

puts File.dirname(__FILE__)

namespace :pg do
  desc "Install the latest stable release of PostgreSQL."
  task :install, roles: :db, only: {primary: true} do
    run "#{sudo} add-apt-repository -y ppa:pitti/postgresql"
    run "#{sudo} apt-get -y update"
    run "#{sudo} apt-get -y install postgresql libpq-dev"
  end

  desc "Create a database for this application."
  task :init, roles: :db, only: {primary: true} do
    # reset the database and role
    run %Q{#{sudo} -u postgres psql -c "CREATE USER #{postgresql_user} WITH PASSWORD '#{postgresql_password}';"}
    run %Q{#{sudo} -u postgres psql -c "CREATE DATABASE #{postgresql_database} OWNER #{postgresql_user};"}
  end

  desc "Reset the database and role for this application."
  task :reset, roles: :db, only: {primary: true} do
    # drop the database and role
    run %Q{#{sudo} -u postgres psql -c "DROP DATABASE #{postgresql_database};"}
    run %Q{#{sudo} -u postgres psql -c "DROP ROLE #{postgresql_user};"}
  end

  desc "Generate the database.yml configuration file."
  task :setup, roles: :app do
    run "mkdir -p #{shared_path}/config"
    template "postgresql.yml.erb", "#{shared_path}/config/database.yml"
  end

  desc "Symlink the database.yml file into latest release"
  task :symlink, roles: :app do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
  end
end
