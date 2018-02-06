define ebs::attach (
  $device          = '/dev/sdz',
  $device_attached = '/dev/xvdad',
  $tag_key         = 'name',
) {

  require ebs

  Exec {
    path => '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin'
  }

  $volume_id_file = "/var/lib/puppet/.ebs__${name}__volume_id"
  $aws_region = inline_template("<%= @ec2_placement_availability_zone.gsub(/.$/,'') %>")

  exec { "EBS volume ${name}: obtaining the volume id":
    command     => "aws ec2 describe-volumes --color off --filters Name=availability-zone,Values=${ec2_placement_availability_zone} Name=status,Values=available Name='tag:${tag_key}',Values=${name} --query 'Volumes[*].[VolumeId]' --output text | head -n 1 > ${volume_id_file}",
    unless      => "test -s ${volume_id_file}",
    environment => "AWS_DEFAULT_REGION=${aws_region}"
  } ->

  exec { "EBS volume ${name}: volume id sanity check":
    command => "[ `wc -l ${volume_id_file} | awk '{print \$1}'` -eq 1 ]"
  } ->

  exec { "EBS volume ${name}: attaching the volume":
    command     => "aws ec2 attach-volume --volume-id `cat ${volume_id_file}` --instance-id $ec2_instance_id --device $device",
    environment => "AWS_DEFAULT_REGION=${aws_region}",
    unless      => "test -b ${device_attached}",
  } ->

  exec { "EBS volume ${name}: waiting for the volume to be attached":
    command   => "lsblk -fn ${device_attached}",
    tries     => 6,
    try_sleep => 10,
    logoutput => true
  }
}
