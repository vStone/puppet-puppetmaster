# == Class puppetmaster::database
#
# Handles database creation.
#
# === Parameters:
#
# $userhost:: What 'hostname' to use when creating the rights on the database.
#             Defaults to 'localhost' if the server is also localhost.
#             Defaults to the fqdn of this machine for other cases.
#
#
class puppetmaster::database (
  $ensure   = 'present',
  $password = $::puppetmaster::database_password,
  $database = $::puppetmaster::database,
  $user     = $::puppetmaster::database_user,
  $server   = $::puppetmaster::database_server,
  $userhost = undef,
) inherits puppetmaster {

  $_userhost = $userhost ? {
    undef   => $server ? {
      'localhost' => 'localhost',
      default     => $::fqdn,
    },
    default => $userhost,
  }

  if $server == 'localhost' {
    # Start using percona as server if we dont have it yet.
    if ! defined(Class['percona']) {
      class {'percona':
        server => true,
      }
    }

    # Create the database and user.
    percona::database {$database:
      ensure => 'present',
    }

    percona::rights {"${user}@${_userhost}/${database}":
      password => $password,
      require  => Percona::Database[$database],
      before   => Class['foreman::config::database'],
    }
  }


}
