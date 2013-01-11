class puppetmaster::pre {

  host {$::fqdn:
    ensure       => 'present',
    ip           => '127.0.0.1',
    host_aliases => [
      "puppetmaster.${::domain}", 'puppetmaster',
      "foreman.${::domain}", 'foreman',
      $::hostname, 'localhost',
    ],
  }

}
