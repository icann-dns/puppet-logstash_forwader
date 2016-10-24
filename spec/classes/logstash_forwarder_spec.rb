require 'spec_helper'

describe 'logstash_forwarder' do
  # by default the hiera integration uses hiera data from the shared_contexts.rb file
  # but basically to mock hiera you first need to add a key/value pair
  # to the specific context in the spec/shared_contexts.rb file
  # Note: you can only use a single hiera context per describe/context block
  # rspec-puppet does not allow you to swap out hiera data on a per test block
  # include_context :hiera
  let(:node) { 'logstash_forwarder.example.com' }

  # below is the facts hash that gives you the ability to mock
  # facts on a per describe/context block.  If you use a fact in your
  # manifest you should mock the facts below.
  let(:facts) do
    {}
  end

  # below is a list of the resource parameters that you can override.
  # By default all non-required parameters are commented out,
  # while all required parameters will require you to add a value
  let(:params) do
    {
      logstash_server: 'logstash.example.com',
      logstash_cert_source: 'puppet:///modules/module_files/logstash.pem',
      #:logstash_port => "5000",
      #:service_name => "logstash-forwarder",
      #:syslog_enable => true,
      #:syslog_pattern => "*.warn",
      #:syslog_file => "/var/log/logstash_syslog",
      #:logrotate_enable => true,
      #:logrotate_rotate => "5",
      #:logrotate_size => "100M",
      #:conf_file => "$::logstash_forwarder::params::conf_file",
      #:logstash_cert_dir => "$::logstash_forwarder::params::logstash_cert_dir",
      #:files => {},

    }
  end
  # add these two lines in a single test block to enable puppet and hiera debug mode
  # Puppet::Util::Log.level = :debug
  # Puppet::Util::Log.newdestination(:console)
  # This will need to get moved
  # it { pp catalogue.resources }
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end
      case facts[:operatingsystem]
      when 'Ubuntu'
        let(:conf_file) { '/etc/logstash-forwarder.conf' }
        let(:logstash_cert_dir) { '/etc/ssl/certs' }
      else
        let(:conf_file) { '/usr/local/etc/logstash-forwarder.conf' }
        let(:logstash_cert_dir) { '/etc/ssl' }
      end
      let(:logstash_cert_file) { "#{logstash_cert_dir}/logstash.example.com.pem" }
      describe 'check default config' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('logstash_forwarder') }
        it { is_expected.to contain_class('logstash_forwarder::params') }
        it { is_expected.to contain_package('logstash-forwarder') }
        it do
          is_expected.to contain_file(logstash_cert_file).with_source(
            'puppet:///modules/module_files/logstash.pem'
          )
        end
        it do
          is_expected.to contain_file('/etc/logstash-forwarder').with_ensure(
            'absent'
          )
        end
        it do
          is_expected.to contain_file(conf_file).with(
            'notify' => 'Service[logstash-forwarder]',
            'require' => 'Package[logstash-forwarder]'
          ).with_content(
            %r{"servers": \[ "logstash.example.com:5000" \]}
          ).with_content(
            %r{"ssl ca": "#{logstash_cert_file}"}
          ).with_content(
            %r{"paths": \[ "/var/log/logstash_syslog" \]}
          )
        end
        it do
          is_expected.to contain_service('logstash-forwarder').with(
            'ensure' => 'running',
            'enable' => true,
            'require' => 'Package[logstash-forwarder]'
          )
        end
        if facts[:kernel] == 'Linux'
          it do
            is_expected.to contain_file('/etc/rsyslog.d/logstash.conf').with(
              'ensure' => 'present'
            ).with_content(
              %r{# managed by Puppet}
            ).with_content(
              %r{\*\.warn /var/log/logstash_syslog}
            )
          end
          it do
            is_expected.to contain_logrotate__rule('logstash_syslog').with(
              'path' => '/var/log/logstash_syslog',
              'rotate' => 5,
              'size' => '100M',
              'compress' => true,
              'postrotate' => '/usr/sbin/service logstash-forwarder restart'
            )
          end
        else
          it do
            is_expected.to contain_file_line('logstash forwader syslog').with(
              'path' => '/etc/syslog.conf',
              'line' => '*.warn /var/log/logstash_syslog'
            )
          end
          it do
            is_expected.to contain_file_line('logstash forwader rotate').with(
              'path' => '/etc/newsyslog.conf',
              'line' => "/var/log/logstash_syslog\t\t644\t7\t*\t*\tJC"
            )
          end
        end
      end
      describe 'Change Defaults' do
        context 'logstash_server' do
          before { params.merge!(logstash_server: 'foo.bar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(conf_file).with_content(
              %r{"servers": \[ "foo.bar:5000" \]}
            ).with_content(
              %r{"ssl ca": "#{logstash_cert_dir}/foo.bar.pem"}
            )
          end
          it do
            is_expected.to contain_file("#{logstash_cert_dir}/foo.bar.pem").with_source(
              'puppet:///modules/module_files/logstash.pem'
            )
          end
        end
        context 'logstash_cert_source' do
          before { params.merge!(logstash_cert_source: 'puppet:///modules/foo/bar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(logstash_cert_file).with_source(
              'puppet:///modules/foo/bar'
            )
          end
        end
        context 'logstash_port' do
          before { params.merge!(logstash_port: 1337) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(conf_file).with_content(
              %r{"servers": \[ "logstash.example.com:1337" \]}
            )
          end
        end
        context 'service_name' do
          before { params.merge!(service_name: 'foo-bar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_service('foo-bar').with(
              'ensure' => 'running',
              'enable' => true,
              'require' => 'Package[logstash-forwarder]'
            )
          end
        end
        context 'syslog_enable' do
          before { params.merge!(syslog_enable: false) }
          it { is_expected.to compile }
          it { is_expected.not_to contain_file('/etc/rsyslog.d/logstash.conf') }
          it { is_expected.not_to contain_file_line('logstash forwader syslog') }
        end
        context 'syslog_pattern' do
          before { params.merge!(syslog_pattern: '*.error') }
          it { is_expected.to compile }
          if facts[:kernel] == 'Linux'
            it do
              is_expected.to contain_file('/etc/rsyslog.d/logstash.conf').with(
                'ensure' => 'present'
              ).with_content(
                %r{\*\.error /var/log/logstash_syslog}
              )
            end
          else
            it do
              is_expected.to contain_file_line('logstash forwader syslog').with(
                'path' => '/etc/syslog.conf',
                'line' => '*.error /var/log/logstash_syslog'
              )
            end
          end
        end
        context 'syslog_file' do
          before { params.merge!(syslog_file: '/foo/bar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(conf_file).with_content(
              %r{"paths": \[ "/foo/bar" \]}
            )
          end
        end
        context 'logrotate_enable' do
          before { params.merge!(logrotate_enable: false) }
          it { is_expected.to compile }
          it { is_expected.not_to contain_logrotate__rule('logstash_syslog') }
          it { is_expected.not_to contain_file_line('logstash forwader rotate') }
        end
        context 'logrotate_rotate' do
          before { params.merge!(logrotate_rotate: 10) }
          it { is_expected.to compile }
          if facts[:kernel] == 'Linux'
            it do
              is_expected.to contain_logrotate__rule('logstash_syslog').with(
                'path' => '/var/log/logstash_syslog',
                'rotate' => 10
              )
            end
          end
        end
        context 'logrotate_size' do
          before { params.merge!(logrotate_size: '1G') }
          it { is_expected.to compile }
          if facts[:kernel] == 'Linux'
            it do
              is_expected.to contain_logrotate__rule('logstash_syslog').with(
                'path' => '/var/log/logstash_syslog',
                'size' => '1G'
              )
            end
          end
        end
        context 'conf_file' do
          before { params.merge!(conf_file: '/foo/bar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/foo/bar').with(
              'notify' => 'Service[logstash-forwarder]',
              'require' => 'Package[logstash-forwarder]'
            ).with_content(
              %r{"servers": \[ "logstash.example.com:5000" \]}
            ).with_content(
              %r{"ssl ca": "#{logstash_cert_file}"}
            ).with_content(
              %r{"paths": \[ "/var/log/logstash_syslog" \]}
            )
          end
        end
        context 'logstash_cert_dir' do
          before { params.merge!(logstash_cert_dir: '/foo/bar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(conf_file).with_content(
              %r{"ssl ca": "/foo/bar/logstash.example.com.pem"}
            )
          end
          it do
            is_expected.to contain_file('/foo/bar/logstash.example.com.pem').with_source(
              'puppet:///modules/module_files/logstash.pem'
            )
          end
        end
        context 'files' do
          before { params.merge!(files: {}) }
          it { is_expected.to compile }
          # Add Check to validate change was successful
        end
      end
      describe 'check bad type' do
        context 'logstash_server' do
          before { params.merge!(logstash_server: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'logstash_cert_source' do
          before { params.merge!(logstash_cert_source: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'logstash_port' do
          before { params.merge!(logstash_port: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'service_name' do
          before { params.merge!(service_name: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'syslog_enable' do
          before { params.merge!(syslog_enable: 'foobar') }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'syslog_pattern' do
          before { params.merge!(syslog_pattern: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'syslog_file' do
          before { params.merge!(syslog_file: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'logrotate_enable' do
          before { params.merge!(logrotate_enable: 'foobar') }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'logrotate_rotate' do
          before { params.merge!(logrotate_rotate: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'logrotate_size' do
          before { params.merge!(logrotate_size: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'conf_file' do
          before { params.merge!(conf_file: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'logstash_cert_dir' do
          before { params.merge!(logstash_cert_dir: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'files' do
          before { params.merge!(files: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
      end
    end
  end
end
