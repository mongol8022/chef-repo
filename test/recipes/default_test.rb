# # encoding: utf-8

# Inspec test for recipe testcook::default

# The Inspec reference, with examples and extensive documentation, can be
# found at https://docs.chef.io/inspec_reference.html

#require 'spec_helper'

#Check if necessary packages to deploy WordPress CMS installed

describe package('nginx') do
  it { should be_installed }
end

describe package('php-fpm') do
  it { should be_installed }
end

describe package('php-mysql') do
  it { should be_installed }
end

describe package('mariadb-server') do
  it { should be_installed }
end


#Check if necessary services enabled and running

describe service('nginx') do
  it { should be_enabled }
  it { should be_running }
end

describe service('php-fpm') do
  it { should be_enabled }
  it { should be_running }
end

describe service('mariadb') do
  it { should be_enabled }
  it { should be_running }
end

#Check if nginx and wordpress config files added to specified locations

describe file('/etc/nginx/conf.d/wordpress.conf') do
  it { should exist }
end

describe file('/var/www/wordpress/wp-config.php') do
  it { should exist }
end

#Check if http port is listening (ngnx working and serving http connections)

describe port(80) do
  it { should be_listening }
end

