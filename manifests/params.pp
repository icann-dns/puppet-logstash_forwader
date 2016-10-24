# == Class: logstash_forwarder::params
#
class logstash_forwarder::params {
  $conf_file = $::kernel ? {
    default   => '/etc/logstash-forwarder.conf',
    'FreeBSD' => '/usr/local/etc/logstash-forwarder.conf',
  }
  $logstash_cert_dir = $::kernel ? {
    default   => '/etc/ssl/certs',
    'FreeBSD' => '/etc/ssl',
  }
}
