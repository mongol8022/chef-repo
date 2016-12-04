require 'chef/provisioning/docker_driver'

machine "wpserver" do
  recipe 'testcook'
#  chef_environment chef_env
  machine_options :docker_options => {
    :base_image => {
    :name => 'centos',
    :repository => 'centos',
    :tag => '7.2'
  },
  :command => 'service nginx start && service php-fpm start && service mariadb start',
 }
end