[![Build Status](https://travis-ci.org/icann-dns/puppet-logstash_forwarder.svg?branch=master)](https://travis-ci.org/icann-dns/puppet-logstash_forwarder)
[![Puppet Forge](https://img.shields.io/puppetforge/v/icann/logstash_forwarder.svg?maxAge=2592000)](https://forge.puppet.com/icann/logstash_forwarder)
[![Puppet Forge Downloads](https://img.shields.io/puppetforge/dt/icann/logstash_forwarder.svg?maxAge=2592000)](https://forge.puppet.com/icann/logstash_forwarder)
# logstash_forwarder

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with logstash_forwarder](#setup)
    * [What logstash_forwarder affects](#what-logstash_forwarder-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with logstash_forwarder](#beginning-with-logstash_forwarder)
4. [Usage - Configuration options and additional functionality](#usage)
    * [Manage client and server](#manage-client-and-server)
    * [Ansible client](#logstash_forwarder-client)
    * [Ansible Server](#logstash_forwarder-server)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
    * [Classes](#classes)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

This module installs logstash_forwarder and can also manage the custom scripts, host script and custom modules directories

## Setup

### What logstash_forwarder affects

* installs logstash_forwarder 
* Adds a syslog entry for logstash
* Optionally rotate the logstash log file

### Setup Requirements **OPTIONAL**

* puppetlabs-stdlib 4.12.0
* icann-tea 0.2.5
* icann-logrotate 

### Beginning with logstash_forwarder

The logstash host and the SSL certificate source locations are both mandadory parameters

```puppet
class {'::logstash_forwarder':
  logstash_server => 'logstash.example.com',
  logstash_cert_source => 'puppet:///modules/mod_files/logstash.pem',
}
```

## Reference

### Classes

#### Public Classes

* [`logstash_forwarder`](#class-logstash_forwarder)

#### Private Classes

* [`logstash_forwarder::params`](#class-logstash_forwarderparams)

#### Class: `logstash_forwarder`

Main class

##### Parameters 

* `logstash_server` (Tea::Host, Default: undef): The host name or IP address of the logstash server
* `logstash_cert_source` (Tea::Puppetsource, Default: undef): This is a string which will be passed the file type source paramter and treated as the file containing the logstash public key
* `logstash_port` (Tea::Port, Default: 5000): The port of the logstash server
* `service_name` (String, Default: 'logstash-forwarder'): name of the service to mnanage
* `syslog_enable` (Boolean, Default: true): redirect syslog entries to a logstash file
* `syslog_pattern` (String, Default: '*.warn'): The syslog pattern to forward to logstash
* `syslog_file` (Tea::Absolutepath, Default: /var/log/logstash_syslog): file file location to redirect syslog messages to
* `logrotate_enable` (Boolean, Default: true): Rotate the file used for syslog messages
* `logrotate_rotate` (Integer[1,1000], Default: 5): how many copys of the syslog file to keep with logrotate
* `logrotate_size` (String, Default: '100M'): how large a file is allowed to be before its rotated
* `conf_file` (Tea::Absolutepath, Default: os specific): location of the logstash forwader config file
* `logstash_cert_dir` (Tea::Absolutepath, Default: os specific): location where to store the logstash public certificate
* `files` (Array[Logstash_forwarder::File), default: undef): An array of hashes. Each hash tells what paths to watch and what fields to annotate on events from those paths (https://github.com/elastic/logstash-forwarder).

## Limitations

This module is tested on Ubuntu 12.04, and 14.04 and FreeBSD 10 

