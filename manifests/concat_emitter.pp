#
# defined type ipfilter::concat
#
# This class builds the ipfilter rule file using RIPienaar's concat module
# We build it using several fragments.
# Being the sequence of lines important we define these boundaries:
# 01 - General header
# Note that the ipfilter::rule define
# inserts (by default) its rules with priority 20.
#
define ipfilter::concat_emitter(
  $emitter_target,
  $is_ipv6 = false
) {

  include ipfilter

  $real_icmp = $is_ipv6 ? {
    true    => 'ipv6_',
    default => '',
  }

  concat { $emitter_target:
    mode   => $ipfilter::config_file_mode,
    owner  => $ipfilter::config_file_owner,
    group  => $ipfilter::config_file_group,
    notify => Service['ipfilter'],
    backup => '.previous',
  }


  # The File Header. With Puppet comment
  concat::fragment{ "ipfilter_header_${name}":
    target  => $emitter_target,
    content => "## File Managed by Puppet\n",
    order   => 01,
    notify  => Service['ipfilter'],
  }

  # The default block policy
  concat::fragment{ "ipfilter_block_${name}":
    target  => $emitter_target,
    content => template("ipfilter/concat/${ipfilter::frag_block_policy}"),
    order   => 05,
    notify  => Service['ipfilter'],
  }

  # The icmp policy
  concat::fragment{ "ipfilter_icmp_${name}":
    target  => $emitter_target,
    content => template("ipfilter/concat/${real_icmp}${ipfilter::frag_icmp_policy}"),
    order   => 10,
    notify  => Service['ipfilter'],
  }

  # The default ssh rule
  concat::fragment{ "ipfilter_ssh_${name}":
    ensure  => $ipfilter::manage_ssh,
    target  => $emitter_target,
    content => template('ipfilter/concat/safe_ssh'),
    order   => 15,
    notify  => Service['ipfilter'],
  }

  # The default output policy
  concat::fragment{ "output_policy_${name}":
    target  => $emitter_target,
    content => template("ipfilter/concat/${ipfilter::frag_output_policy}"),
    order   => 80,
    notify  => Service['ipfilter'],
  }
}
