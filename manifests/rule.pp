# Define: ipfilter::rule
#
# Adds a custom ipfilter rule
# Supported arguments:
# $direction - Direction in or out for which the rule should apply
# $action - The ipfilter action to take block | "pass" | log | "count" | skip | auth
# $source - The packets source address (ipf.conf "addr" supported syntax, default any)
# $source_v6 - The packets IPv6 source address
# $destination - The packets destination (ipf.conf "addr" supported syntax, default any)
# $destination_v6 - The packets IPv6 destination
# $protocol - The transport protocol (as in /etc/protocols, default tcp)
# $port - The DESTINATION port
# $order - The CONCAT order where to place your rule. By default this is automatically
# calculated if you want to set it be sure of what you're doing and check
# ipfilter::concat_emitter to see current order numbers in order to avoid building a wrong ipfilter rule file
# $rule - A custom ipfilter rule (in whatever ipfilter supported format). Use this as
# an alternative to the use of the above $protocol, $port, $source and $destination parameters.
#
# Note that s single call to ipfilter::rule creates a rule with the following content:
# # Rule "name"
# $action $direction quick proto $protocol from $source to $destination [port = $port] [keep state]
#
# Note that $rule is currently not working.
# $enable -
# $enable_v6 - enables the IPv6 part. Default is false for compatibility reasons.
#
define ipfilter::rule (
  $direction      = 'in',
  $action         = 'pass',
  $source         = 'any',
  $source_v6      = 'any',
  $destination    = '<thishost>',
  $destination_v6 = '<thishost>',
  $protocol       = 'tcp',
  $port           = '',
  $order          = '',
  $rule           = '',
  $enable         = true,
  $enable_v6      = false,
  $debug          = false ) {

  include ipfilter
  include concat::setup

  # If (concat) order is not defined we find out the right one
  $true_order = $order ? {
    ''      => '20',
    default => $order,
  }

  # We build the rule if not explicitely set
  $true_protocol = $protocol ? {
    ''      => '',
    default => "proto ${protocol}",
  }
  $state = $protocol ? {
    'tcp'   => ' keep state',
    'udp'   => ' keep state',
    default => undef,
  }

  $true_port = $port ? {
    ''       => '',
    /^\d+$/   => "port = ${port}",
    default  => "port ${port}",
  }

  $ensure = bool2ensure($enable)

  $array_source = is_array($source) ? {
    false     => $source ? {
      ''      => [],
      default => [$source],
    },
    default   => $source,
  }

  $array_destination = is_array($destination) ? {
    false     => $destination ? {
      ''      => [],
      default => [$destination],
    },
    default   => $destination,
  }

  $array_source_v6 = is_array($source_v6) ? {
    false     => $source_v6 ? {
      ''      => [],
      default => [$source_v6],
    },
    default   => $source_v6,
  }

  $array_destination_v6 = is_array($destination_v6) ? {
    false     => $destination_v6 ? {
      ''      => '',
      default => [$destination_v6],
    },
    default   => $destination_v6,
  }

  if $debug {
    ipfilter::debug{ "debug params ${name}":
      true_port            => $true_port,
      true_protocol        => $true_protocol,
      array_source_v6      => $array_source_v6,
      array_destination_v6 => $array_destination_v6,
      array_source         => $array_source,
      array_destination    => $array_destination,
    }
  }

  concat::fragment{ "ipfilter_rule_${name}":
    ensure  => $ensure,
    target  => $ipfilter::config_file,
    content => template('ipfilter/concat/rule.erb'),
    order   => $true_order,
    notify  => Service['ipfilter'],
  }

  if $enable_v6 {
    concat::fragment{ "ipfilter_rule_v6_${name}":
      ensure  => $ensure,
      target  => $ipfilter::config_file_v6,
      content => template('ipfilter/concat/rule_v6.erb'),
      order   => $true_order,
      notify  => Service['ipfilter'],
    }
  }
}
