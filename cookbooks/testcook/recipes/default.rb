#
# Cookbook Name:: testcook
# Recipe:: default
#
# Copyright 2016, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

# Install epel repo for possibility to install nginx package
package 'epel-release'  do
  action :install
end

#execute 'install-epelrepo' do
#  command 'yum -y install epel-release'
#    action :run
#    end

# Install necessary packages for WordPress CMS
package ['nginx', 'php-fpm', 'php-mysql', 'mariadb-server']  do
  action :install
end

# update 'php.ini' file to template 'php.erb' where 
# 'memory_limit' directive increased to 512M
template '/etc/php.ini' do
    source 'php.erb'
    mode '0644'
    owner 'root'
    group 'root'
end

#add nginx virtualhost config for WordPress site
template '/etc/nginx/conf.d/wordpress.conf' do
    source 'wordpress.erb'
    mode '0644'
    owner 'root'
    group 'root'
end

#enable and start installed services
service 'php-fpm' do
    action [:enable, :start]
end

service 'nginx' do
    action [:enable, :start]
end

service 'mariadb' do
    action [:enable, :start]
end

#create an empty database for wordpress app and grant all privs on it
#to wordpress user
execute 'db-initial' do
  command 'mysql -e \'create database wordpress;\' && mysql -e \'GRANT ALL PRIVILEGES ON wordpress.* TO "wpuser"@"localhost" IDENTIFIED BY "wppass";\' && mysql -e \'FLUSH PRIVILEGES;\''
    ignore_failure true
end


#deploy WordPress from git using private repo (auth by key)

# install git if not already installed
package 'git'  do
  action :install
end

directory '/tmp/.ssh' do
    mode '0755'
    action :create
end

directory '/var/www/wordpress' do
    mode '0755'
    action :create
end

directory '/root/.ssh' do
    mode '0755'
    action :create
end


template '/tmp/.ssh/wrap-ssh4git.sh' do
    source 'wrap-ssh4git.erb'
    mode '0770'
end

template '/root/.ssh/deploy_key_pub' do
    source 'deploy_key_pub.erb'
    mode '0600'
end

template '/root/.ssh/deploy_key' do
    source 'deploy_key.erb'
    mode '0600'
end

deploy 'private_repo' do
    repo 'git@github.com/WordPress/WordPress.git'
    user 'nginx'
    deploy_to '/var/www/wordpress'
    ssh_wrapper '/tmp/.ssh/wrap-ssh4git.sh'
    action :deploy
end

# delete temporary dirs
directory '/tmp/.ssh' do
    action :delete
    recursive true
end

directory '/root/.ssh' do
    action :delete
    recursive true
end


#wordpress config creation
template '/var/www/wordpress/wp-config.php' do
    source 'wp-config.erb'
    mode '0644'
end