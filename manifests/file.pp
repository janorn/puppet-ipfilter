#
# Class ipfilter::file
#
# This class configures ipfilter via a base rule file
# The file itselt is not provided. Use this class to
# manage the ipfilter file in the way you want
#
# It's used if $ipfilter_config = "file"
#
class ipfilter::file inherits ipfilter {

  file { 'ipfilter.conf':
    ensure  => $ipfilter::manage_file,
    path    => $ipfilter::config_file,
    mode    => $ipfilter::config_file_mode,
    owner   => $ipfilter::config_file_owner,
    group   => $ipfilter::config_file_group,
    require => Package[$ipfilter::package],
    notify  => $ipfilter::manage_service_autorestart,
    source  => $ipfilter::manage_file_source,
    content => $ipfilter::manage_file_content,
    replace => $ipfilter::manage_file_replace,
    audit   => $ipfilter::manage_audit,
  }

}
