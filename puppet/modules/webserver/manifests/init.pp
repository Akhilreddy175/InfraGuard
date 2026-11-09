class webserver (
  String $site_title = 'INT333 Automated Web Server',
) {
  package { 'nginx': ensure => installed }

  file { '/var/www/html/index.html':
    ensure  => file,
    content => epp('webserver/index.html.epp', { 'title' => $site_title }),
    require => Package['nginx'],
    notify  => Service['nginx'],
  }

  service { 'nginx':
    ensure => running,
    enable => true,
  }
}
