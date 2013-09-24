# Class: ipfilter::params
#
# Sets internal variables and defaults for ipfilter module
# This class is loaded in all the classes that use the values set here
#
class ipfilter::params  {

  ### Definition of some variables used in the module
  $osver = split($::operatingsystemrelease, '[.]')
  $osver_maj = $osver[0]

  $enable_v6 = false

## DEFAULTS FOR VARIABLES USERS CAN SET

# Define how you want to manage ipfilter configuration:
# "file" - To provide ipfilter rules as a normal file
# "concat" - To build them up using different fragments
#      - This option, set as default, permits the use of the ipfilter::rule define
#      - and many other funny things
  $config = 'concat'

# Define what to do with unknown packets
  $block_policy = 'drop'

# Define what to do with icmp packets (quick'n'dirty approach)
  $icmp_policy = 'accept'

# Define what to do with output packets
  $output_policy = 'accept'

## Define what packets to log
  $log = 'drop'
  $log_input = ''
  $log_output = ''
  $log_forward = ''

# Define the Level of logging (numeric or see syslog.conf(5))
  $log_level = '4'

# Define if you want to open SSH port by default
  $safe_ssh = true

# Define what to do with INPUT broadcast packets
  $broadcast_policy = 'accept'

# Define what to do with INPUT multicast packets
  $multicast_policy = 'accept'
  
# Location of ipf helper script
  $helper = '/etc/ipf/ipf-helper.sh'

## MODULE INTERNAL VARIABLES
# (Modify to adapt to unsupported OSes)

  $package = $::operatingsystem ? {
    /(?i:Solaris)/ => $::kernelrelease ? {
      '5.10'  => ['SUNWipfr','SUNWipfu'],
      default => 'ipfilter',
    },
  }

  $service = $::operatingsystem ? {
    default => 'svc:/network/ipfilter:default',
  }

  $service_status = true

  case $::operatingsystem {
    /(?i:Solaris)/: {
      $config_file = '/etc/ipf/ipf.conf'
      $config_file_v6 = '/etc/ipf/ipf6.conf'
    }
    default: {
    }
  }

  $config_file_mode = $::operatingsystem ? {
    default => '0640',
  }

  $config_file_owner = $::operatingsystem ? {
    default => 'root',
  }

  $config_file_group = $::operatingsystem ? {
    default => 'sys',
  }

  $my_class = ''
  $source = ''
  $template = ''
  $service_autorestart = true
  $version = 'present'
  $absent = false
  $disable = false
  $disableboot = false
  $debug = false
  $audit_only = false

  ## FILE SERVING SOURCE
  case $::base_source {
    '': {
      $general_base_source = $::puppetversion ? {
        /(^0.25)/ => 'puppet:///modules',
        /(^0.)/   => "puppet://${servername}",
        default   => 'puppet:///modules',
      }
    }
    default: { $general_base_source = $::base_source }
  }

}
