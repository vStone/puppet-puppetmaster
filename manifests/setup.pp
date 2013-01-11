class puppetmaster::setup (
  $database               = $::puppetmaster::database,
  $database_adapter       = $::puppetmaster::database_adapter,
  $database_user          = $::puppetmaster::database_user,
  $database_password      = $::puppetmaster::database_password,
  $database_server        = $::puppetmaster::database_server,
  $foreman_servername     = $::puppetmaster::foreman_servername,
  $puppet_version         = $::puppetmaster::puppet_version,
  $puppet_servername      = $::puppetmaster::puppet_servername,
  $puppet_ssl_dir         = $::puppetmaster::puppet_ssl_dir,
  $puppet_module_subtrees = $::puppetmaster::puppet_module_subtrees,
) inherits puppetmaster {

  require puppetmaster::database

  $database_settings = {
    'adapter'  => $database_adapter,
    'database' => $database,
    'host'     => $database_server,
    'username' => $database_user,
    'password' => $database_password,
  }

  #$puppet_version = $::operatingsystem ? {
  #  /(?i:centos)/ => '3.0.2-1.el6',
    #/(?i:centos)/ => '2.7.20-1.el6',
    #/(?i:debian)/ => '2.7.20-1puppetlabs1',
    #  default       => 'present',
  #}



  class {'puppet':
    version         => $puppet_version,
    #    servername      => $puppet_servername,
  }
  class {'puppet::server':
    version              => $puppet_version,
    modules_subtrees     => $puppet_module_subtrees,
    storeconfig_settings => $database_settings,
    storeconfigs         => true,
    passenger            => false,
    service_fallback     => false,
    servername           => $puppet_servername,
    git_repo             => false,
    dynamic_envs         => true,
    ssl_dir              => $puppet_ssl_dir,
    agent_template       => 'puppetmaster/puppet-agent.conf.erb',
    #  master_template   => 'puppetmaster/puppet-server.conf.erb',
  }
  class {'puppet::server::rack': }

  file {'/var/lib/puppet-server':
    ensure  => 'directory',
    owner   => $::puppet::server::user,
    group   => $::puppet::server::group,
    mode    => '0750',
    require => [
      Class['puppet::server::install'],
    ],
    before => [
      Exec['generate_ca_cert'],
    ],
  }


  class {'foreman':
    enc               => true,
    unattended        => false,
    storeconfigs      => true,
    passenger         => false,
    custom_repo       => true,
    database_settings => $database_settings,
  }
  include foreman::service::disabled

  class {'foreman_proxy':
    tftp => false,
    ssl  => true,
  }


  include passenger
  include apache
  include apache::mod::passenger
  include apache::mod::headers
  apache::listen {'8140': }
  apache::vhost::ssl {'puppetmaster_8140':
    servername        => $puppet_servername,
    port              => '8140',
    serveraliases     => [$::fqdn, 'puppetmaster'],
    ssl_cert          => $puppet::server::ssl_cert,
    ssl_key           => $puppet::server::ssl_cert_key,
    ssl_chain         => $puppet::server::ssl_chain,
    ssl_ca_file       => $puppet::server::ssl_ca_cert,
    ssl_ca_crl_file   => $puppet::server::ssl_ca_crl,
    ssl_options       => '+StdEnvVars',
    ssl_verify_client => 'optional',
    ssl_verify_depth  => '1',
    docroot           => $puppet::server::doc_root,
    dirroot           => $puppet::server::app_root,
    mods              => {

      'passenger'         => {
        passenger_enabled => true,
        rack_autodetect   => true,
        content           => "
  # The following client headers allow the same configuration
  # to work with Pound
  RequestHeader set X-SSL-Subject %{SSL_CLIENT_S_DN}e
  RequestHeader set X-Client-DN %{SSL_CLIENT_S_DN}e
  RequestHeader set X-Client-Verify %{SSL_CLIENT_VERIFY}e
  ",
      }
    },
    require           => [
      Exec['generate_ca_cert'], ## Need ssl certs.
      Class['puppet::server::rack'],
    ],
  }

  apache::listen {'443': }

  #apache::namevhost {'443': }

  # Required so that the apache module does not wipe the folder since
  # this is a symlink and is not detected as directory.
  file {'/usr/share/foreman/public':
    ensure  => 'present',
    require => Package['foreman'],
  } ->
  apache::vhost::ssl {'foreman_443':
    servername      => $foreman_servername,
    port            => '443',
    serveraliases   => [
      'foreman',
      $puppet_servername,
      $::fqdn
    ],
    ssl_cert        => $puppet::server::ssl_cert,
    ssl_key         => $puppet::server::ssl_cert_key,
    ssl_chain       => $puppet::server::ssl_chain,
    ssl_ca_file     => $puppet::server::ssl_ca_cert,
    ssl_ca_crl_file => $puppet::server::ssl_ca_crl,
    docroot         => "${foreman::params::app_root}/public",
    mods            => {
      'passenger'     => {
        'app_root'          => $foreman::params::app_root,
        'passenger_enabled' => true,
        'rails_autodetect'  => true,
      }
    },
    require         => Package['foreman'],
  }

  apache::vhost {'default_80':
    servername => $::fqdn,
    mods       => {
      'rewrite'  => {
        rewrite_cond => '%{HTTPS} off',
        rewrite_rule => '^/(.*) https://%{SERVER_NAME}/$1 [R,L]',
      },
    }
  }

}
