require 'capistrano-zen/base'

configuration = Capistrano::Configuration.respond_to?(:instance) ?
  Capistrano::Configuration.instance(:must_exist) :
  Capistrano.configuration(:must_exist)

configuration.load do
  namespace :nodejs do
    desc "Install the latest relase of Node.js"
    # Reference
    # https://github.com/joyent/node/wiki/Installing-Node.js-via-package-manager
    task :install, roles: :app do
      #run "#{sudo} add-apt-repository ppa:chris-lea/node.js"
      run "echo -e | #{sudo} add-apt-repository ppa:chris-lea/node.js"
      run "#{sudo} apt-get -y update"
      # Chris-lea's package already includes npm, this results in package conflict
      # See: http://stackoverflow.com/questions/16302436/install-nodejs-on-ubuntu-12-10
      # run "#{sudo} apt-get -y install nodejs npm"
      run "#{sudo} apt-get -y install nodejs"
    end
  end
end
