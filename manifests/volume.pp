define ebs::volume (
  $device          = '/dev/sdz',
  $device_attached = '/dev/xvdad',
  $format          = 'ext3',
  $format_options  = undef,
  $mount_options   = 'noatime',
  $mount_dir       = '/mnt',
  $tag_key         = 'name',
) {

  require ebs

  Exec {
    path => '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin'
  }

  ebs::attach { $name:
    device          => $device,
    device_attached => $device_attached,
    tag_key         => $tag_key,
  } ->

  exec { "EBS volume ${name}: formatting the volume":
    command   => "mkfs.${format} ${format_options} ${device_attached}",
    unless    => "lsblk -fn ${device_attached} | grep -q ' ${format} '",
    logoutput => true
  } ->

  exec { "EBS volume ${name}: creating the mount directory":
    command => "mkdir -p ${mount_dir}",
    unless  => "test -d ${mount_dir}"
  } ->

  mount { $mount_dir:
    ensure  => mounted,
    device  => $device_attached,
    fstype  => $format,
    options => $mount_options
  }

}
