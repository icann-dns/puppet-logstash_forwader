# == Class: logstash_forwarder
#
class logstash_forwarder (
  Tea::Host         $logstash_server      = undef,
  Tea::Puppetsource $logstash_cert_source = undef,
  Tea::Port         $logstash_port        = 5000,
  String            $service_name         = 'logstash-forwarder',
  Boolean           $syslog_enable        = true,
  String            $syslog_pattern       = '*.warn',
  Tea::Absolutepath $syslog_file          = '/var/log/logstash_syslog',
  Boolean           $logrotate_enable     = true,
  Integer[1,1000]   $logrotate_rotate     = 5,
  String            $logrotate_size       = '100M',
  Tea::Absolutepath $conf_file            = $::logstash_forwarder::params::conf_file,
  Tea::Absolutepath $logstash_cert_dir    = $::logstash_forwarder::params::logstash_cert_dir,
  Optional[Array[Logstash_forwarder::File]] $files  = undef
) inherits logstash_forwarder::params {

  $syslog_line = "${syslog_pattern} ${syslog_file}"
  $logstash_cert = "${logstash_cert_dir}/${logstash_server}.pem"
  ensure_packages(['logstash-forwarder'])

  file{ $logstash_cert:
    source => $logstash_cert_source;
  '/etc/logstash-forwarder':
    ensure => absent;
  $conf_file:
    content => template('logstash_forwarder/logstash-forwarder.erb'),
    notify  => Service[$service_name],
    require => Package['logstash-forwarder'];
  }
  service {$service_name:
    ensure  => running,
    enable  => true,
    require => Package['logstash-forwarder'];
  }
  case $::kernel {
    default: {
      file {'/var/lib/logstash-forwarder':
        ensure => directory,
        mode   => '0750',
      }
      if $syslog_enable {
        file {'/etc/rsyslog.d/logstash.conf':
          ensure  => present,
          content => "# managed by Puppet\n${syslog_line}\n",
        }
      }
      if $logrotate_enable {
        logrotate::rule {
          'logstash_syslog':
            path       => $syslog_file,
            rotate     => $logrotate_rotate,
            size       => $logrotate_size,
            compress   => true,
            postrotate => "/usr/sbin/service ${service_name} restart",
        }
      }
    }
    'FreeBSD': {
      if $syslog_enable {
        file_line {'logstash forwader syslog':
          path => '/etc/syslog.conf',
          line => $syslog_line,
        }
      }
      if $logrotate_enable {
        file_line {'logstash forwader rotate':
          path => '/etc/newsyslog.conf',
          line => "${syslog_file}\t\t644\t7\t*\t*\tJC",
        }
      }
    }
  }
}
