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
#    owner 'root'
#    group 'root'
end

#add nginx virtualhost config for WordPress site
directory '/etc/nginx/conf.d' do
    mode '0755'
    action :create
end


template '/etc/nginx/conf.d/wordpress.conf' do
    source 'wordpress.erb'
    mode '0644'
#    owner 'root'
#    group 'root'
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



# store database credentials in encrypted databag

# 1. Encrypted databag secret file was generated: openssl rand -base64 512 > ~/chef_repo/.chef/encrypted_data_bag_secret
# 2. Option 'knife[:secret_file]  = "#{current_dir}/encrypted_data_bag_secret"' added to 'knife.rb'
# 2. Encrypted databag and item with id 'credentials' was created: knife data bag create db_credentials credentials --encrypt
# 3. In editor mode three items, insted of 'id' were added (see below):
# \{
#  "id": "credentials",
#  "user": "wpuser",
#  "pass": "wppass",
#  "db": "wordpress"
# \}
# 5. Encrypted databag secret file was copied to the specified node: scp ~/chef-repo/.chef/encrypted_data_bag_secret root@chefclient.example.com:/etc/chef/

secret = Chef::EncryptedDataBagItem.load_secret("/etc/chef/encrypted_data_bag_secret")
db_credentials = Chef::EncryptedDataBagItem.load("db_credentials", "credentials.json", secret)
mysql_user = db_credentials["user"]
mysql_pass = db_credentials["pass"]
mysql_db = db_credentials["db"]

# create an empty database for wordpress app and grant all privs on it
# to wordpress user
execute 'db-initial' do
    command "mysql -e \"create database #{mysql_db};\" && mysql -e \"GRANT ALL PRIVILEGES ON #{mysql_db}.* TO #{mysql_user}@localhost IDENTIFIED BY \\\"#{mysql_pass}\\\";\" && mysql -e \"FLUSH PRIVILEGES;\""
#ignore_failure true
end


# deploy WordPress from git using private repo (auth by key)

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


# wordpress config creation
# db credentials load from encrypted databag items
template '/var/www/wordpress/wp-config.php' do
    source 'wp-config.erb'
    mode '0644'
    variables({
        :mysql_user => db_credentials["user"],
        :mysql_db => db_credentials["db"],
        :mysql_pass => db_credentials["pass"]
          })
end