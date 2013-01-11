# == Class: puppetmaster
#
# Sets up a puppetmaster with foreman as ENC. Also sets up the smart-proxy.
#
# === Parameters:
#
# $database::           (Local) database to create. If set to false or undef,
#                       creation of the local database is not executed.
#
# $database_adapter::   Database adapter to use for foreman/puppetmaster.
#                       Defaults to 'mysql2'.
#
# $database_user::      Database user to create and/or use in configuration.
#
# $database_password::  Database password to set and/or use in configuration.
#
# $database_server::    Hostname of the database. Only required when the
#                       database server is not running on the same machine as
#                       the puppetmaster/foreman.
#
# $foreman_servername:: The name the foreman interface will be available on.
#                       This can be different from the fqdn of the machine and
#                       it defaults to "foreman.${::domain}". Additional
#                       serveraliases are added to the vhost configuration:
#                       the puppet_servername and fqdn.
#
# $puppet_version::     Override the client/server puppet versions to install.
#                       Defaults to 'present'. (which is latest available).
#
# $puppet_servername::  The name to use for the puppetmaster.
#                       This can be different from the fqdn of the machine
#                       but has to be available in your dns setup to all
#                       your hosts. It defaults to "puppetmaster.${domain}".
#
# $puppet_ssl_dir::     Defaults to '/var/lib/puppet-server/ssl'
#
# $puppet_module_subtrees::
#
#
#
#
# === Requires:
#
# * Puppet modules:
#   - percona (git://github.com/UnifiedPost/puppet-percona.git)
#   - foreman (git://github.com/vStone/puppet-foreman.git)
#   - puppet  (git://github.com/vStone/puppet-puppet.git)
#   - apache  (git://github.com/vStone/puppet-apache.git)
#   - passenger (git://github.com/UnifiedPost/puppet-passenger.git)
#
class puppetmaster (
  $database          = 'puppet',
  $database_adapter  = 'mysql2',
  $database_user     = 'puppet',
  $database_password = 'puppet',
  $database_server   = 'localhost',
  $foreman_servername = "foreman.${::domain}",
  $puppet_version    = 'present',
  $puppet_servername = "puppetmaster.${::domain}",
  $puppet_ssl_dir    = '/var/lib/puppet-server/ssl',
  $puppet_module_subtrees = ['upstream', 'internal', 'dev'],
) {

  if ! defined (Stage['pre']) {
    stage {'pre': before => Stage['main'], }
  }

  class {'puppetmaster::pre':
    stage => 'pre',
  }

  class {'puppetmaster::database': } ->
  class {'puppetmaster::config': } ->
  class {'puppetmaster::setup':
    require => Class['puppetmaster::database'],
  }

}
