# vg_hostname comes from puppet facts declared in Vagrantfile

$redmine_install_dir = "/usr/src/redmine"

package { 'libssl-dev':
  ensure => present
} ->
package { 'zlib1g-dev':
  ensure => present
} ->
class { 'postgresql::server':
} ->
class { '::apache':
} ->
class { 'passenger':
  passenger_version      => "4.0.59",
  passenger_provider     => "gem",
  package_ensure         => "4.0.59",
  include_build_tools    => true,
  gem_path               => '/var/lib/gems/2.1.0/gems',
  gem_binary_path        => '/usr/bin/gem',
  passenger_root         => '/var/lib/gems/2.1.0/gems/passenger-4.0.59',
  mod_passenger_location => '/var/lib/gems/2.1.0/gems/passenger-4.0.59/buildout/apache2/mod_passenger.so',
  require => Package["libssl-dev", "zlib1g-dev"]
} ->
class { 'redmine':
  download_url     => 'http://svn.redmine.org/redmine/branches/2.6-stable',
  install_dir      => $redmine_install_dir,
  provider         => 'svn',
  version          => 'HEAD',
  database_adapter => 'postgresql',
  vhost_aliases    => "www.$vg_hostname",
  vhost_servername => "$vg_hostname",
} ->
redmine::plugin { 'redmine_mylyn_connector' :
  source => 'https://github.com/danmunn/redmine_mylyn_connector.git',
} ->
exec {'redmine_configure_hostname_restapi':
  subscribe   => [Exec['rails_migrations'], Service["apache2"]],
  path        => ['/usr/bin', '/usr/sbin', '/bin'],
  environment => ["vg_hostname=$vg_hostname"],
  command     => "ruby $redmine_install_dir/script/rails runner /vagrant/files/configure_redmine.rb -e production",
  onlyif      => "test ! -f $redmine_install_dir/.data_loaded",
  notify      => [Exec['redmine_create_user_tester1']],
  refreshonly => true,
} ->
exec {'redmine_create_user_tester1':
  path        => ['/usr/bin', '/usr/sbin', '/bin'],
  command     => "curl -u admin:admin -X POST -H \'Content-Type: application/xml\' http://$vg_hostname/users.xml -d @/vagrant/files/create_user_tester1.xml",
  onlyif      => "test ! -f $redmine_install_dir/.data_loaded",
  notify      => [Exec['redmine_create_user_developer1']],
  refreshonly => true,
} ->
exec {'redmine_create_user_developer1':
  path        => ['/usr/bin', '/usr/sbin', '/bin'],
  command     => "curl -u admin:admin -X POST -H \'Content-Type: application/xml\' http://$vg_hostname/users.xml -d @/vagrant/files/create_user_developer1.xml",
  onlyif      => "test ! -f $redmine_install_dir/.data_loaded",
  notify      => [Exec['redmine_create_project1']],
  refreshonly => true,
} ->
exec {'redmine_create_project1':
  path        => ['/usr/bin', '/usr/sbin', '/bin'],
  command     => "curl -u admin:admin -X POST -H \'Content-Type: application/xml\' http://$vg_hostname/projects.xml -d @/vagrant/files/create_project_project1.xml",
  onlyif      => "test ! -f $redmine_install_dir/.data_loaded",
  notify      => [Exec['redmine_create_project2']],
  refreshonly => true,
} ->
exec {'redmine_create_project2':
  path        => ['/usr/bin', '/usr/sbin', '/bin'],
  command     => "curl -u admin:admin -X POST -H \'Content-Type: application/xml\' http://$vg_hostname/projects.xml -d @/vagrant/files/create_project_project2.xml",
  onlyif      => "test ! -f $redmine_install_dir/.data_loaded",
  notify      => [Exec['redmine_create_issue1_for_project1']],
  refreshonly => true,
} ->
exec {'redmine_create_issue1_for_project1':
  path        => ['/usr/bin', '/usr/sbin', '/bin'],
  command     => "curl -u admin:admin -X POST -H \'Content-Type: application/xml\' http://$vg_hostname/issues.xml -d @/vagrant/files/create_issue1_for_project1.xml",
  onlyif      => "test ! -f $redmine_install_dir/.data_loaded",
  notify      => [Exec['redmine_create_issue2_for_project1']],
  refreshonly => true,
} ->
exec {'redmine_create_issue2_for_project1':
  path        => ['/usr/bin', '/usr/sbin', '/bin'],
  command     => "curl -u admin:admin -X POST -H \'Content-Type: application/xml\' http://$vg_hostname/issues.xml -d @/vagrant/files/create_issue2_for_project1.xml",
  onlyif      => "test ! -f $redmine_install_dir/.data_loaded",
  notify      => [Exec['redmine_create_issue1_for_project2']],
  refreshonly => true,
} ->
exec {'redmine_create_issue1_for_project2':
  path        => ['/usr/bin', '/usr/sbin', '/bin'],
  command     => "curl -u admin:admin -X POST -H \'Content-Type: application/xml\' http://$vg_hostname/issues.xml -d @/vagrant/files/create_issue1_for_project2.xml",
  onlyif      => "test ! -f $redmine_install_dir/.data_loaded",
  notify      => [Exec['redmine_mark_data_loaded']],
  refreshonly => true,
} ->
exec {'redmine_mark_data_loaded':
  path        => ['/usr/bin', '/usr/sbin', '/bin'],
  command     => "touch $redmine_install_dir/.data_loaded",
  onlyif      => "test ! -f $redmine_install_dir/.data_loaded",
  refreshonly => true,
}

