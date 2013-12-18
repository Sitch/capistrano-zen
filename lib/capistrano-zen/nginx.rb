require 'capistrano-zen/base'

configuration = Capistrano::Configuration.respond_to?(:instance) ?
  Capistrano::Configuration.instance(:must_exist) :
  Capistrano.configuration(:must_exist)

configuration.load do
  _cset(:nginx_use_ssl, false)

  if nginx_use_ssl
    _cset(:nginx_ssl_certificate) { "#{domain}.crt" }
    _cset(:nginx_ssl_certificate_key) { "#{domain}.key" }
    _cset(:nginx_upload_local_ssl_certificate) { true }
    _cset(:nginx_ssl_certificate_path) { "#{config_path}/ssl/#{nginx_ssl_certificate}" }
    _cset(:nginx_ssl_certificate_key_path) { "#{config_path}/ssl/#{nginx_ssl_certificate_key}"}
  end

  namespace :nginx do
    desc "Install latest stable release of nginx"
    task :install, roles: :web do
      # run "#{sudo} add-apt-repository ppa:nginx/stable"
      run "echo -e | #{sudo} add-apt-repository ppa:nginx/stable"
      run "#{sudo} apt-get -y update"
      run "#{sudo} apt-get -y install nginx"
      run "#{sudo} rm -f /etc/nginx/sites-enabled/default"
    end

    namespace :setup do
      desc "Setup nginx configuration for unicorn application"
      task :unicorn, roles: :web do
        template "nginx_unicorn.erb", "/tmp/nginx_conf"
        run "#{sudo} mv /tmp/nginx_conf /etc/nginx/sites-enabled/#{application}"
        run "#{sudo} rm -f /etc/nginx/sites-enabled/default"

        if nginx_use_ssl
          if nginx_upload_local_ssl_certificate
            put File.read(nginx_ssl_certificate_path), "/tmp/#{nginx_ssl_certificate}"
            put File.read(nginx_ssl_certificate_key_path), "/tmp/#{nginx_ssl_certificate_key}"

            run "#{sudo} mv /tmp/#{nginx_ssl_certificate} /etc/ssl/#{nginx_ssl_certificate}"
            run "#{sudo} mv /tmp/#{nginx_ssl_certificate_key} /etc/ssl/#{nginx_ssl_certificate_key}"
          end

          run "#{sudo} chown root:root /etc/ssl/#{nginx_ssl_certificate}"
          run "#{sudo} chown root:root /etc/ssl/#{nginx_ssl_certificate_key}"
        end

        restart
      end

      desc "Setup nginx configuration for static website"
      task :static, roles: :web do
        template "nginx_static.erb", "/tmp/nginx_conf"
        run "#{sudo} mv /tmp/nginx_conf /etc/nginx/sites-enabled/#{application}"
        restart
      end
    end

    %w[start stop restart reload].each do |command|
      desc "#{command} nginx"
      task command, roles: :web do
        run "#{sudo} service nginx #{command}"
      end
    end
  end
end
