# == Class: ipfilter
#
# This is a Puppet module for ipfilter based on the iptables module of Example42 Puppet Modules.
#
# === Parameters
#
# Document parameters here.
#
# $config              - Use a 'file' or the 'concat' module. Default concat.
# $source              - Source for config file if concat modules isn't used.
# $template            - Template for config file.
# $service_autorestart - Restart ipfilters automaticly when config changes. (true)
# $block_policy        - Block policy. Default drop all pkgs in and out.
# $icmp_policy         - Policy for icmp pkgs. Default allow all.
# $output_policy       - Default outgoing policy. Default allow everything from localhost.
# $broadcast_policy    - N/A
# $multicast_policy    - N/A
# $log                 - All blocked pkgs are being dropped.
# $log_input           - N/A
# $log_output          - N/A
# $log_forward         - N/A
# $log_level           - Currently using default ipf:
#                        block = Error (short pkgs)
#                        block = Warning
#                        pass  = Notice
#                        log   = info
# $safe_ssh            - Enable incoming ssh rule from any. Default true.
# $package             - Software pkgs require for ipfilter.
# $version             - N/A
# $service             - Service name for ipfilter
# $service_status      - Does service have status? Default true.
# $helper              - IPF helper to reload new rules safely. In case of errors
#                        the previous config will be restored.
# $config_file         - IPF config file. Default /etc/ipf/ipf.conf
# $config_file_mode    - Default file mode '0640'
# $config_file_owner   - Default owner 'root'
# $config_file_group   - Default group 'sys'
# $absent              - Untested
# $disable             - Untested
# $disableboot         - Untested
# $debug               - Untested
# $enable_v6           - Untested
# $audit_only          - Enable Puppets builtin audit
#
# === Requirements
#
# This module requires stdlib, puppi and concat modules.
#
# === Examples
#
#  class { ipfilter:
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ]
#  }
#
# === Authors
#
# https://github.com/janorn
#
# === Copyright
#
# Copyright 2013 janorn here, unless otherwise noted.
#
class ipfilter (
  $config              = $ipfilter::params::config,
  $source              = $ipfilter::params::source,
  $template            = $ipfilter::params::template,
  $service_autorestart = $ipfilter::params::service_autorestart,
  $block_policy        = $ipfilter::params::block_policy,
  $icmp_policy         = $ipfilter::params::icmp_policy,
  $output_policy       = $ipfilter::params::output_policy,
  $broadcast_policy    = $ipfilter::params::broadcast_policy,
  $multicast_policy    = $ipfilter::params::multicast_policy,
  $log                 = $ipfilter::params::log,
  $log_input           = $ipfilter::params::log_input,
  $log_output          = $ipfilter::params::log_output,
  $log_forward         = $ipfilter::params::log_forward,
  $log_level           = $ipfilter::params::log_level,
  $safe_ssh            = $ipfilter::params::safe_ssh,
  $package             = $ipfilter::params::package,
  $version             = $ipfilter::params::version,
  $service             = $ipfilter::params::service,
  $service_status      = $ipfilter::params::service_status,
  $helper              = $ipfilter::params::helper,
  $config_file         = $ipfilter::params::config_file,
  $config_file_mode    = $ipfilter::params::config_file_mode,
  $config_file_owner   = $ipfilter::params::config_file_owner,
  $config_file_group   = $ipfilter::params::config_file_group,
  $absent              = $ipfilter::params::absent,
  $disable             = $ipfilter::params::disable,
  $disableboot         = $ipfilter::params::disableboot,
  $debug               = $ipfilter::params::debug,
  $enable_v6           = $ipfilter::params::enable_v6,
  $audit_only          = $ipfilter::params::audit_only,
  ) inherits ipfilter::params {

  $bool_service_autorestart = str2bool($service_autorestart)
  $bool_absent = str2bool($absent)
  $bool_disable = str2bool($disable)
  $bool_disableboot = str2bool($disableboot)
  $bool_debug = str2bool($debug)
  $bool_audit_only = str2bool($audit_only)

  ### Dependencies
  Class['stdlib'] -> Class['ipfilter']

  ### Definitions of specific variables
  $frag_block_policy = $block_policy ? {
    'drop'    => 'block_header_drop',
    'DROP'    => 'block_header_drop',
    'reject'  => 'block_header_reject',
    'REJECT'  => 'block_header_reject',
    'accept'  => 'block_header_accept',
    'ACCEPT'  => 'block_header_accept',
    default   => 'block_header_drop',
  }

  $frag_icmp_policy = $icmp_policy ? {
    'drop'    => 'icmp_header_drop',
    'DROP'    => 'icmp_header_drop',
    'safe'    => 'icmp_header_safe',
    'accept'  => 'icmp_header_accept',
    'ACCEPT'  => 'icmp_header_accept',
    default   => 'icmp_header_accept',
  }

  $frag_output_policy = $output_policy ? {
    'drop'    => 'output_footer_drop',
    'DROP'    => 'output_footer_drop',
    default   => 'output_footer_accept',
  }

  $real_log = $log ? {
    'all'     => 'all',
    'dropped' => 'drop',
    'none'    => 'no',
    'no'      => 'no',
    default   => 'drop',
  }
  $real_log_input = $log_input ? {
    ''        => $real_log,
    'all'     => 'all',
    'dropped' => 'drop',
    'none'    => 'no',
    'no'      => 'no',
    default   => 'drop',
  }
  $real_log_output = $log_output ? {
    ''        => $real_log,
    'all'     => 'all',
    'dropped' => 'drop',
    'none'    => 'no',
    'no'      => 'no',
    default   => 'drop',
  }
  $real_log_forward = $log_forward ? {
    ''        => $real_log,
    'all'     => 'all',
    'dropped' => 'drop',
    'none'    => 'no',
    'no'      => 'no',
    default   => 'drop',
  }

  $real_safe_ssh = str2bool($safe_ssh)

  $manage_ssh = $real_safe_ssh ? {
    false => absent ,
    true  => present ,
  }

  $real_broadcast_policy = $broadcast_policy ? {
    'drop'    => 'drop',
    'DROP'    => 'drop',
    default   => 'accept',
  }

  $real_multicast_policy = $multicast_policy ? {
    'drop'    => 'drop',
    'DROP'    => 'drop',
    default   => 'accept',
  }


  ### Definition of some variables used in the module
  $manage_package = $ipfilter::bool_absent ? {
    true  => 'absent',
    false => $ipfilter::version,
  }

  $manage_service_enable = $ipfilter::bool_disableboot ? {
    true    => false,
    default => $ipfilter::bool_disable ? {
      true    => false,
      default => $ipfilter::bool_absent ? {
        true  => false,
        false => true,
      },
    },
  }

  $manage_service_ensure = $ipfilter::bool_disable ? {
    true    => 'stopped',
    default =>  $ipfilter::bool_absent ? {
      true    => 'stopped',
      default => 'running',
    },
  }

  $manage_service_autorestart = $ipfilter::bool_service_autorestart ? {
    true    => Service['ipfilter'],
    false   => undef,
  }

  $manage_file = $ipfilter::bool_absent ? {
    true    => 'absent',
    default => 'present',
  }

  $manage_audit = $ipfilter::bool_audit_only ? {
    true  => 'all',
    false => undef,
  }

  $manage_file_replace = $ipfilter::bool_audit_only ? {
    true  => false,
    false => true,
  }

  $manage_file_source = $ipfilter::source ? {
    ''        => undef,
    default   => $ipfilter::source,
  }

  $manage_file_content = $ipfilter::template ? {
    ''        => undef,
    default   => template($ipfilter::template),
  }

  case $::operatingsystem {
    debian: { require ipfilter::debian }
    ubuntu: { require ipfilter::debian }
    default: { }
  }

  # Basic Package - Service - Configuration file management
  package { $ipfilter::package:
    ensure => $ipfilter::manage_package,
  }

  file { $ipfilter::helper:
    ensure => $manage_file,
    owner  => 'root',
    group  => 'root',
    mode   => '0744',
    source => 'puppet:///modules/ipfilter/ipf-helper.sh',
  }

  service { 'ipfilter':
    ensure     => $ipfilter::manage_service_ensure,
    name       => $ipfilter::service,
    enable     => $ipfilter::manage_service_enable,
    hasstatus  => $ipfilter::service_status,
    require    => [Package[$ipfilter::package],File[$ipfilter::helper]],
    hasrestart => true,
    restart    => "${ipfilter::helper} reload",
  }

  # How to manage ipfilter configuration
  case $ipfilter::config {
    'file': { include ipfilters::file }
    'concat': {
      ipfilter::concat_emitter { 'v4':
        emitter_target => $ipfilter::config_file,
        is_ipv6        => false,
      }
      if $enable_v6 {
        ipfilter::concat_emitter { 'v6':
          emitter_target => $ipfilter::config_file_v6,
          is_ipv6        => true,
        }
      }
    }
    default: { }
  }

  ### Debugging, if enabled ( debug => true )
  if $ipfilter::bool_debug == true {
    file { 'debug_ipfilter':
      ensure  => $ipfilter::manage_file,
      path    => "${settings::vardir}/debug-ipfilter",
      mode    => '0640',
      owner   => 'root',
      group   => 'root',
      content => inline_template('<%= scope.to_hash.reject { |k,v| k.to_s =~ /(uptime.*|path|timestamp|free|.*password.*|.*psk.*|.*key)/ }.to_yaml %>'),
    }
  }
}
