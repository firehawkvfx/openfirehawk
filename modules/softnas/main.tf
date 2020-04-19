#variable "name" {}
# resource "aws_cloudformation_stack" "SoftNASRole" {
#   name         = "${var.cloudformation_role_stack_name}"
#   capabilities = ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM"]
#   template_url = "https://s3-ap-southeast-2.amazonaws.com/aws-softnas-cloudformation/softnas-role.json"
# }

resource "aws_iam_role" "softnas_role" {
  name = "SoftNAS_HA_IAM"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Action": [
              "sts:AssumeRole"
          ],
          "Principal": {
              "Service": [
                  "ec2.amazonaws.com"
              ]
          },
          "Effect": "Allow"
      }
  ]
}
EOF

}

resource "aws_iam_instance_profile" "softnas_profile" {
  name = "SoftNAS_HA_IAM"
  role = aws_iam_role.softnas_role.name
}

resource "aws_iam_role_policy_attachment" "softnas_ssm_attach" {
  role       = aws_iam_role.softnas_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_role_policy" "softnas_policy" {
  name = "SoftNAS_HA_IAM"
  role = aws_iam_role.softnas_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Sid": "Stmt1444200186000",
          "Effect": "Allow",
          "Action": [
              "ec2:ModifyInstanceAttribute",
              "ec2:DescribeInstances",
              "ec2:CreateVolume",
              "ec2:DeleteVolume",
              "ec2:CreateSnapshot",
              "ec2:DeleteSnapshot",
              "ec2:CreateTags",
              "ec2:DeleteTags",
              "ec2:AttachVolume",
              "ec2:DetachVolume",
              "ec2:DescribeInstances",
              "ec2:DescribeVolumes",
              "ec2:DescribeSnapshots",
              "aws-marketplace:MeterUsage",
              "ec2:DescribeRouteTables",
              "ec2:DescribeAddresses",
              "ec2:DescribeTags",
              "ec2:DescribeInstances",
              "ec2:ModifyNetworkInterfaceAttribute",
              "ec2:ReplaceRoute",
              "ec2:CreateRoute",
              "ec2:DeleteRoute",
              "ec2:AssociateAddress",
              "ec2:DisassociateAddress",
              "s3:CreateBucket",
              "s3:Delete*",
              "s3:Get*",
              "s3:List*",
              "s3:Put*"
          ],
          "Resource": [
              "*"
          ]
      }
  ]
}
EOF

}

locals {
  softnas_mode_ami = "${var.softnas_mode}_${var.aws_region}"
}

resource "random_uuid" "test" {
}

resource "aws_security_group" "softnas" {
  count = var.softnas_storage ? 1 : 0

  name        = "softnas"
  vpc_id      = var.vpc_id
  description = "SoftNAS security group"

  tags = {
    Name = "softnas"
  }

  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [var.remote_subnet_cidr, var.vpc_cidr, var.public_subnets_cidr_blocks[0], var.vpn_cidr]
    description = "all incoming traffic"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 53
    to_port     = 53
    cidr_blocks = [var.remote_subnet_cidr, var.vpc_cidr, var.public_subnets_cidr_blocks[0], var.vpn_cidr]
    description = "DNS"
  }

  ingress {
    protocol    = "udp"
    from_port   = 53
    to_port     = 53
    cidr_blocks = [var.remote_subnet_cidr, var.vpc_cidr, var.public_subnets_cidr_blocks[0], var.vpn_cidr]
    description = "DNS"
  }

  ingress {
    protocol    = "icmp"
    from_port   = 8
    to_port     = 0
    cidr_blocks = [var.remote_subnet_cidr, var.vpc_cidr, var.public_subnets_cidr_blocks[0], var.vpn_cidr]
    description = "icmp"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = [var.remote_subnet_cidr, var.vpc_cidr, var.public_subnets_cidr_blocks[0], var.vpn_cidr]
    description = "ssh"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = [var.remote_subnet_cidr, var.vpc_cidr, var.public_subnets_cidr_blocks[0], var.vpn_cidr]
    description = "https"
  }

  # ingress {
  #   protocol    = "udp"
  #   from_port   = 1194
  #   to_port     = 1194
  #   cidr_blocks = ["${var.remote_subnet_cidr}", "${var.vpc_cidr}", "${var.public_subnets_cidr_blocks[0]}", "${var.vpn_cidr}"]
  #   description = "from softnas default template"
  # }

  ingress {
    protocol    = "tcp"
    from_port   = 0
    to_port     = 65535
    cidr_blocks = [var.remote_subnet_cidr, var.vpc_cidr, var.vpn_cidr]
    description = "all incoming traffic from remote vpn"
  }

  ingress {
    protocol    = "udp"
    from_port   = 49152
    to_port     = 65535
    cidr_blocks = [var.remote_subnet_cidr, var.vpc_cidr, var.vpn_cidr]
    description = ""
  }

  ingress {
    protocol    = "tcp"
    from_port   = 111
    to_port     = 111
    cidr_blocks = [var.remote_subnet_cidr, var.vpc_cidr, var.vpn_cidr]
    description = "NFS"
  }

  ingress {
    protocol    = "udp"
    from_port   = 111
    to_port     = 111
    cidr_blocks = [var.remote_subnet_cidr, var.vpc_cidr, var.vpn_cidr]
    description = "NFS"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 892
    to_port     = 892
    cidr_blocks = [var.remote_subnet_cidr, var.vpc_cidr, var.vpn_cidr]
    description = "rquotad, nlockmgr, mountd, status"
  }

  ingress {
    protocol    = "udp"
    from_port   = 892
    to_port     = 892
    cidr_blocks = [var.remote_subnet_cidr, var.vpc_cidr, var.vpn_cidr]
    description = "rquotad, nlockmgr, mountd, status"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 2010
    to_port     = 2010
    cidr_blocks = [var.remote_subnet_cidr, var.vpc_cidr, var.vpn_cidr]
    description = "rquotad, nlockmgr, mountd, status"
  }

  ingress {
    protocol    = "udp"
    from_port   = 2010
    to_port     = 2010
    cidr_blocks = [var.remote_subnet_cidr, var.vpc_cidr, var.vpn_cidr]
    description = "rquotad, nlockmgr, mountd, status"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 2014
    to_port     = 2014
    cidr_blocks = [var.remote_subnet_cidr, var.vpc_cidr, var.vpn_cidr]
    description = "rquotad, nlockmgr, mountd, status"
  }

  ingress {
    protocol    = "udp"
    from_port   = 2014
    to_port     = 2014
    cidr_blocks = [var.remote_subnet_cidr, var.vpc_cidr, var.vpn_cidr]
    description = "rquotad, nlockmgr, mountd, status"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 2049
    to_port     = 2049
    cidr_blocks = [var.remote_subnet_cidr, var.vpc_cidr, var.vpn_cidr]
    description = "rquotad, nlockmgr, mountd, status"
  }

  ingress {
    protocol    = "udp"
    from_port   = 2049
    to_port     = 2049
    cidr_blocks = [var.remote_subnet_cidr, var.vpc_cidr, var.vpn_cidr]
    description = "rquotad, nlockmgr, mountd, status"
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "all outgoing traffic"
  }
}

variable "allow_prebuilt_softnas_ami" {
}

data "aws_ami_ids" "softnas_platinum_consumption_higher" {
  owners = ["679593333241"] # the softnas account id
  filter {
    name   = "description"
    values = ["SoftNAS Cloud Platinum - Consumption - 4.3.0"]
  }
}

data "aws_ami_ids" "softnas_platinum_consumption_lower" {
  owners = ["679593333241"] # the softnas account id
  filter {
    name   = "description"
    values = ["SoftNAS Cloud Platinum - Consumption (For Lower Compute Requirements) - 4.3.0"]
  }
}

variable "softnas_performance" {
  default = "softnas_platinum_consumption_higher"
}

locals {
  keys = ["softnas_platinum_consumption_higher","softnas_platinum_consumption_lower"]
  values = ["${element( data.aws_ami_ids.softnas_platinum_consumption_higher.ids, 0 )}", "${element( data.aws_ami_ids.softnas_platinum_consumption_lower.ids, 0 )}"]
  softnas_platinum_consumption_map = zipmap( local.keys , local.values )
}

locals { # select the found ami to use based on the map lookup
  base_ami = lookup(local.softnas_platinum_consumption_map, var.softnas_performance)
}

data "aws_ami_ids" "prebuilt_softnas_ami_list" { # search for a prebuilt tagged ami with the same base image.  if there is a match, it can be used instead, allowing us to skip updates.
  owners = ["self"]
  filter {
    name   = "tag:base_ami"
    values = ["${local.base_ami}"]
  }
  filter {
    name = "name"
    values = ["softnas_prebuilt_*"]
  }
}

locals {
  prebuilt_softnas_ami_list = data.aws_ami_ids.prebuilt_softnas_ami_list.ids
  first_element = element( data.aws_ami_ids.prebuilt_softnas_ami_list.*.ids, 0)
  mod_list = concat( local.prebuilt_softnas_ami_list , list("") )
  aquired_ami      = "${element( local.mod_list , 0)}" # aquired ami will use the ami in the list if found, otherwise it will default to the original ami.
  use_prebuilt_softnas_ami = var.allow_prebuilt_softnas_ami && length(local.mod_list) > 1 ? true : false
  ami = local.use_prebuilt_softnas_ami ? local.aquired_ami : local.base_ami
}

output "base_ami" {
  value = local.base_ami
}

output "prebuilt_softnas_ami_list" {
  value = local.prebuilt_softnas_ami_list
}

output "first_element" {
  value = local.first_element
}

output "aquired_ami" {
  value = local.aquired_ami
}

output "use_prebuilt_softnas_ami" {
  value = local.use_prebuilt_softnas_ami
}

output "ami" {
  value = local.ami
}

# resource "aws_network_interface" "nas1eth0" {
#   count = var.softnas_storage ? 1 : 0
#   subnet_id       = var.private_subnets[0]
#   private_ips     = [var.softnas1_private_ip1]
#   security_groups = aws_security_group.softnas.*.id

#   tags = {
#     Name = "primary_network_interface"
#   }
# }

# resource "aws_network_interface" "nas1eth1" {
#   count = var.softnas_storage ? 1 : 0
#   subnet_id       = var.private_subnets[0]
#   private_ips     = [var.softnas1_private_ip2]
#   security_groups = aws_security_group.softnas.*.id

#   tags = {
#     Name = "secondary_network_interface"
#   }
# }

resource "aws_instance" "softnas1" {
  count = var.softnas_storage ? 1 : 0
  # depends_on = [ aws_instance.softnas1, var.vpn_private_ip, aws_network_interface.nas1eth0, aws_network_interface.nas1eth1 ]
  depends_on = [ aws_instance.softnas1, var.vpn_private_ip ]

  ami   = local.ami

  instance_type = var.instance_type[var.softnas_mode]

  ebs_optimized = true

  iam_instance_profile = aws_iam_instance_profile.softnas_profile.name

  # network_interface {
  #   device_index         = 0
  #   network_interface_id = element(concat(aws_network_interface.nas1eth0.*.id, list("")), 0)
  #   #delete_on_termination = true
  # }

  # network_interface {
  #   device_index         = 1
  #   network_interface_id = element(concat(aws_network_interface.nas1eth1.*.id, list("")), 0)
  #   #delete_on_termination = true
  # }

  subnet_id      = element(concat(var.private_subnets, list("")), count.index)
  private_ip     = var.softnas1_private_ip1
  vpc_security_group_ids = aws_security_group.softnas.*.id

  root_block_device {
    volume_size = "100"
    volume_type = "gp2"
    delete_on_termination = true
    # if specifying a snapshot, do not specify encryption.
    #encryption = false
  }

  key_name = var.key_name
  user_data = <<USERDATA
#cloud-config
hostname: nas1
fqdn: nas1
manage_etc_hosts: false
USERDATA


  tags = {
    Name  = "SoftNAS1_PlatinumConsumption${var.softnas_mode}Compute"
    Route = "private"
    Role  = "softnas"
  }
}

# When using ssd tiering, you must manually create the ebs volumes and specify the ebs id's in your secrets.  Then they can be locally restored automatically and attached to the instance.

locals {
  id = element(concat(aws_instance.softnas1.*.id, list("")), 0)
  provision_softnas         = local.use_prebuilt_softnas_ami ? false : true # when using an aquired ami, we will not create another ami as this would replace it.
  skip_packages = local.use_prebuilt_softnas_ami # when using an aquired ami, we will not create another ami as this would replace it.
}

resource "null_resource" "wait_softnas_up" {
  count      = ( !var.sleep && var.softnas_storage ) ? 1 : 0
  depends_on = [aws_instance.softnas1]

  triggers = {
    instanceid = "${join(",", aws_instance.softnas1.*.id)}"
    skip_update = var.skip_update
  }

  # some time is required before the ecdsa key file exists.
  # some time is required before the ecdsa key file exists.
  provisioner "remote-exec" {
    connection {
      user                = var.softnas_ssh_user
      host                = aws_instance.softnas1[0].private_ip
      bastion_host        = var.bastion_ip
      bastion_user        = "centos"
      private_key         = var.private_key
      bastion_private_key = var.private_key
      type                = "ssh"
      timeout             = "10m"
    }

    # sleep 300 is required because ecdsa key wont exist for a while, and you can't continue without it.
    inline = [
      "set -x",
      "while [ ! -f /etc/ssh/ssh_host_ecdsa_key.pub ]",
      "do",
      "  sleep 10",
      "done",
      "cat /etc/ssh/ssh_host_ecdsa_key.pub",
      "cat /etc/ssh/ssh_host_rsa_key.pub",
      "cat /etc/ssh/ssh_host_ecdsa_key.pub",
      "ssh-keyscan ${aws_instance.softnas1[0].private_ip}",
      "which python",
      "python --version",
      "rm -fv /etc/udev/rules.d/70-persistent-net.rules", # this file may need to be removed in order to create an image that will work.
      # "sudo yum install -y python",
    ]
  }
}

resource "random_id" "ami_init_unique_name" {
  count = local.create_ami && var.softnas_storage ? 1 : 0
  depends_on = [
    aws_instance.softnas1,
    null_resource.wait_softnas_up,
  ]
  keepers = { # Generate a new id each time we switch to a new instance id, or the base_ami cahanges.  this doesn't mean a new ami is generated.
    ami_id = local.id
    base_ami = local.base_ami
  }
  byte_length = 8
}

# This init ami is for testing to verify the base image can be used with other instances.  In some versions of softnas this stage has failed.
resource "null_resource" "create_ami_init" {
  count = local.create_ami && var.softnas_storage ? 1 : 0
  depends_on = [
    aws_instance.softnas1,
    null_resource.wait_softnas_up,
  ]
  triggers = {
    instanceid = "${join(",", aws_instance.softnas1.*.id)}"
    base_ami = local.base_ami
  }
  provisioner "remote-exec" {
    connection {
      user                = var.softnas_ssh_user
      host                = aws_instance.softnas1[0].private_ip
      bastion_host        = var.bastion_ip
      bastion_user        = "centos"
      private_key         = var.private_key
      bastion_private_key = var.private_key
      type                = "ssh"
      timeout             = "10m"
    }
    inline = ["set -x && echo 'booted'"]
  }
  provisioner "local-exec" {
    command = <<EOT
      set -x
      cd /deployuser
      # ami creation is unnecesary since softnas ami update.  will be needed in future again if softnas updates slow down deployment.
      ansible-playbook -i "$TF_VAR_inventory" ansible/aws-ami.yaml -v --extra-vars "instance_id=${aws_instance.softnas1.*.id[count.index]} ami_name=softnas_init_${local.ami} base_ami=${local.ami} description=softnas1_${aws_instance.softnas1.*.id[count.index]}_${random_id.ami_init_unique_name[0].hex}"
      aws ec2 start-instances --instance-ids ${aws_instance.softnas1.*.id[count.index]}
EOT
  }
}


resource "null_resource" "provision_softnas" {
  count      = ( !var.sleep && var.softnas_storage ) ? 1 : 0
  depends_on = [aws_instance.softnas1, null_resource.wait_softnas_up, null_resource.create_ami_init, var.vpn_private_ip]

  triggers = {
    instanceid = "${join(",", aws_instance.softnas1.*.id)}"
    skip_update = var.skip_update
  }

  # some time is required before the ecdsa key file exists.
  # some time is required before the ecdsa key file exists.
  provisioner "remote-exec" {
    connection {
      user                = var.softnas_ssh_user
      host                = aws_instance.softnas1[0].private_ip
      bastion_host        = var.bastion_ip
      bastion_user        = "centos"
      private_key         = var.private_key
      bastion_private_key = var.private_key
      type                = "ssh"
      timeout             = "10m"
    }

    # sleep 300 is required because ecdsa key wont exist for a while, and you can't continue without it.
    inline = [
      "set -x",
      "while [ ! -f /etc/ssh/ssh_host_ecdsa_key.pub ]",
      "do",
      "  sleep 10",
      "done",
      "cat /etc/ssh/ssh_host_ecdsa_key.pub",
      "cat /etc/ssh/ssh_host_rsa_key.pub",
      "cat /etc/ssh/ssh_host_ecdsa_key.pub",
      "ssh-keyscan ${aws_instance.softnas1[0].private_ip}",
      "which python",
      "python --version",
      # "sudo yum install -y python",
    ]
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      . /deployuser/scripts/exit_test.sh
      set -x
      cd /deployuser

      ansible-playbook -i "$TF_VAR_inventory" ansible/ssh-add-private-host.yaml -v --extra-vars "private_ip=${aws_instance.softnas1[0].private_ip} bastion_ip=${var.bastion_ip}"; exit_test
      # ansible-playbook -i "$TF_VAR_inventory" ansible/ssh-add-private-host.yaml -v --extra-vars "variable_host=firehawkgateway variable_user=deployuser private_ip=${aws_instance.softnas1[0].private_ip} bastion_ip=${var.bastion_ip}"; exit_test
      ansible-playbook -i "$TF_VAR_inventory" ansible/inventory-add.yaml -v --extra-vars "host_name=softnas0 host_ip=${aws_instance.softnas1[0].private_ip} group_name=role_softnas insert_ssh_key_string=ansible_ssh_private_key_file=$TF_VAR_local_key_path"; exit_test
      ansible-playbook -i "$TF_VAR_inventory" ansible/get-file.yaml -v --extra-vars "source=/var/log/cloud-init-output.log dest=$TF_VAR_firehawk_path/tmp/cloud-init-output-softnas.log variable_user=ec2-user variable_host=role_softnas"; exit_test

      exit 0

      # Initialise
      ansible-playbook -i "$TF_VAR_inventory" ansible/softnas-init.yaml -v --extra-vars "skip_packages=${local.skip_packages}"; exit_test

      # remove any mounts on local workstation first since they will have been broken if another softnas instance was just destroyed to create this one.
      if [[ $TF_VAR_remote_mounts_on_local == true ]] ; then
        echo "CONFIGURE REMOTE MOUNTS ON LOCAL NODES PROVISION"
        ansible-playbook -i "$TF_VAR_inventory" ansible/node-centos-mounts.yaml --extra-vars "variable_host=workstation1 variable_user=deadlineuser ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_private_ssh_key destroy=true variable_gather_facts=no" --skip-tags 'cloud_install local_install_onsite_mounts' --tags 'local_install'; exit_test
      fi
      if [[ "$TF_VAR_softnas_skip_update" == true ]]; then
        echo "...Skip softnas update"
      else
        ansible-playbook -i "$TF_VAR_inventory" ansible/softnas-update.yaml -v; exit_test
        echo "Finished Update"
      fi
      # cli is only needed if sync operations with s3 will be run on this instance.
      # #ansible-playbook -i "$TF_VAR_inventory" ansible/aws-cli.yaml -v --extra-vars "variable_user=ec2-user variable_host=role_softnas"; exit_test
      # #ansible-playbook -i "$TF_VAR_inventory" ansible/aws-cli-ec2.yaml -v --extra-vars "variable_user=ec2-user variable_host=role_softnas"; exit_test
  
EOT

  }
  provisioner "remote-exec" {
    connection {
      user                = var.softnas_ssh_user
      host                = aws_instance.softnas1[0].private_ip
      bastion_host        = var.bastion_ip
      bastion_user        = "centos"
      private_key         = var.private_key
      bastion_private_key = var.private_key
      type                = "ssh"
      timeout             = "10m"
    }
    inline = ["set -x && echo 'booted after init'"]
  }
}

# when testing, the local can be set to disable ami creation in a dev environment only - for faster iteration.
locals {
  create_ami         = local.use_prebuilt_softnas_ami ? false : true # when using an aquired ami, we will not create another ami as this would replace it.
}

resource "random_id" "ami_unique_name" {
  count = local.create_ami && var.softnas_storage ? 1 : 0
  depends_on = [
    aws_instance.softnas1,
    null_resource.provision_softnas,
  ]
  keepers = { # Generate a new id each time we switch to a new instance id, or the base_ami cahanges.  this doesn't mean a new ami is generated.
    ami_id = local.id
    base_ami = local.base_ami
  }
  byte_length = 8
}

# At this point in time, AMI's created by terraform are destroyed with terraform destroy.  we desire the ami to be persistant for faster future redeployment, so we create the ami with ansible instead.
resource "null_resource" "create_ami" {
  count = local.create_ami && var.softnas_storage ? 1 : 0
  depends_on = [
    aws_instance.softnas1,
    null_resource.provision_softnas,
  ]
  triggers = {
    instanceid = "${join(",", aws_instance.softnas1.*.id)}"
    base_ami = local.base_ami
  }
  provisioner "remote-exec" {
    connection {
      user                = var.softnas_ssh_user
      host                = aws_instance.softnas1[0].private_ip
      bastion_host        = var.bastion_ip
      bastion_user        = "centos"
      private_key         = var.private_key
      bastion_private_key = var.private_key
      type                = "ssh"
      timeout             = "10m"
    }
    inline = ["set -x && echo 'booted'"]
  }
  provisioner "local-exec" {
    command = <<EOT
      set -x
      cd /deployuser
      # ami creation is unnecesary since softnas ami update.  will be needed in future again if softnas updates slow down deployment.
      ansible-playbook -i "$TF_VAR_inventory" ansible/aws-ami.yaml -v --extra-vars "instance_id=${aws_instance.softnas1.*.id[count.index]} ami_name=softnas_prebuilt_${local.ami} base_ami=${local.ami} description=softnas1_${aws_instance.softnas1.*.id[count.index]}_${random_id.ami_unique_name[0].hex}"
      aws ec2 start-instances --instance-ids ${aws_instance.softnas1.*.id[count.index]}
EOT
  }
}

# Start instance so that s3 disks can be attached
resource "null_resource" "start-softnas-after-create-ami" {
  count = local.create_ami && var.softnas_storage ? 1 : 0

  #depends_on         = ["aws_volume_attachment.softnas1_ebs_att"]
  depends_on = [
    null_resource.provision_softnas,
    null_resource.create_ami,
  ]
  provisioner "local-exec" {
    command = "aws ec2 start-instances --instance-ids ${aws_instance.softnas1.*.id[count.index]}"
  }
}

# If ebs volumes are attached, don't automatically import the pool. manual intervention may be required.
locals {
  import_pool = true
  #"${length(local.softnas1_volumes) > 0 ? false : true}"
}

# Once an AMI is built above, then we test the connection to the instance via a bastion below.
# When connection to softnas is established, we know the instance has booted.  We continue to provision an s3 extender disk below.
# this creates an s3 bucket if it doesn't already exist.  if there is a bucket with the same disk_device number, same nas name, and same domain,
# then the existing bucket will be mounted instead and existing data wil be available.  you may need to login to the softnas web ui to import the existing pool and volume,
# but the disk should be mounted correctly.
# Domains can be used to differentiate dev environments from production.
# for example, dev.example.com vs prod.example.com are different namespaces for two different buckets with otherwise identical properties to coexist in the same aws account.
# if an existing bucket is detected, s3_disk_size_max_value and encrypt_s3 are overidden by the settings on the bucket, and commandline variables ignored.
# the s3 encryption password is stored in your encrypted vault in ansible/host_vars/all/vault

# IMPORTANT: if creating a new disk, the disk_device should be the next number available to the instance.
# eg if these are already moujnted, /dev/s3-0, /dev/s3-1, /dev/s3-2, then the disk_device for the next bucket should be "3".

output "softnas1_instanceid" {
  value = aws_instance.softnas1.*.id
}

output "softnas1_private_ip" {
  value = aws_instance.softnas1.*.private_ip
}

# there is currently too much activity here, but due to the way dependencies work in tf 0.11 its better to keep it in one block.
# in tf .12 we should split these up and handle dependencies properly.
resource "null_resource" "provision_softnas_volumes" {
  count      = ( !var.sleep && var.softnas_storage ) ? 1 : 0
  depends_on = [
    null_resource.provision_softnas,
    null_resource.start-softnas-after-create-ami,
    null_resource.create_ami,
  ]

  # "null_resource.start-softnas-after-ebs-attach"
  triggers = {
    instanceid = "${join(",", aws_instance.softnas1.*.id)}"
  }

  provisioner "remote-exec" {
    connection {
      user                = var.softnas_ssh_user
      host                = aws_instance.softnas1[0].private_ip
      bastion_host        = var.bastion_ip
      bastion_user        = "centos"
      private_key         = var.private_key
      bastion_private_key = var.private_key
      type                = "ssh"
      timeout             = "10m"
    }

    inline = ["set -x && echo 'booted'"]
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      . /deployuser/scripts/exit_test.sh
      set -x
      cd /deployuser

      exit 0

      ansible-playbook -i "$TF_VAR_inventory" ansible/node-centos-init-users.yaml -v --extra-vars "variable_host=role_softnas variable_user=$TF_VAR_softnas_ssh_user set_hostname=false"; exit_test
      # hotfix script to speed up instance start and shutdown
      # ansible-playbook -i "$TF_VAR_inventory" ansible/softnas-install-acpid.yaml -v; exit_test

      # ensure all old mounts onsite are removed if they exist.
      if [[ $TF_VAR_remote_mounts_on_local == true ]] ; then
        echo "CONFIGURE REMOTE MOUNTS ON LOCAL NODES"
        ansible-playbook -i "$TF_VAR_inventory" ansible/node-centos-mounts.yaml -v --extra-vars "variable_host=workstation1 variable_user=deadlineuser hostname=workstation1 ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_private_ssh_key destroy=true variable_gather_facts=no" --skip-tags 'cloud_install local_install_onsite_mounts' --tags 'local_install'; exit_test
      fi
      # mount all ebs disks before s3
      ansible-playbook -i "$TF_VAR_inventory" ansible/softnas-check-able-to-stop.yaml -v --extra-vars "instance_id=${aws_instance.softnas1.*.id[count.index]}"; exit_test
      ansible-playbook -i "$TF_VAR_inventory" ansible/softnas-ebs-disk.yaml -v --extra-vars "instance_id=${aws_instance.softnas1.*.id[count.index]} stop_softnas_instance=true mode=attach"; exit_test
      # Although we start the instance in ansible, the aws cli can be more reliable to ensure this.
      aws ec2 start-instances --instance-ids ${aws_instance.softnas1.*.id[count.index]}; exit_test
  
EOT

  }

  # connect to the instance again to ensure it has booted.
  # connect to the instance again to ensure it has booted.
  provisioner "remote-exec" {
    connection {
      user                = var.softnas_ssh_user
      host                = aws_instance.softnas1[0].private_ip
      bastion_host        = var.bastion_ip
      bastion_user        = "centos"
      private_key         = var.private_key
      bastion_private_key = var.private_key
      type                = "ssh"
      timeout             = "10m"
    }

    inline = ["set -x && echo 'booted'"]
  }
  provisioner "local-exec" {
    command = <<EOT
      . /deployuser/scripts/exit_test.sh
      set -x
      cd /deployuser

      exit 0

      # ensure volumes and pools exist after disks are ensured to exist.
      ansible-playbook -i "$TF_VAR_inventory" ansible/softnas-ebs-pool.yaml -v; exit_test
      # ensure s3 disks exist and are mounted.  the s3 features are disabled currently in favour of migrating to using the aws cli and pdg to sync data
      # ansible-playbook -i "$TF_VAR_inventory" ansible/softnas-s3-disk.yaml -v --extra-vars "pool_name=$(TF_VAR_envtier)pool0 volume_name=$(TF_VAR_envtier)volume0 disk_device=0 s3_disk_size_max_value=${var.s3_disk_size} encrypt_s3=true import_pool=${local.import_pool}"; exit_test
      # exports should be updated here.
      # if btier.json exists in /secrets/${var.envtier}/ebs-volumes/ then the tiers will be imported.
      # ansible-playbook -i "$TF_VAR_inventory" ansible/softnas-backup-btier.yaml -v --extra-vars "restore=true"; exit_test
      ansible-playbook -i "$TF_VAR_inventory" ansible/softnas-ebs-disk-update-exports.yaml -v --extra-vars "instance_id=${aws_instance.softnas1.*.id[count.index]}"; exit_test
  
EOT

  }
}

output "provision_softnas_volumes" {
  value = null_resource.provision_softnas_volumes.*.id
}

# todo : need to report success at correct time after it has started.  see email from steven melnikov at softnas to check how to do this.

# wakeup a node after sleep
resource "null_resource" "start-softnas" {
  count      = ( !var.sleep && var.softnas_storage ) ? 1 : 0
  depends_on = [null_resource.provision_softnas_volumes]

  #,"null_resource.mount_volumes_onsite"]

  triggers = {
    instanceid = "${join(",", aws_instance.softnas1.*.id)}"
  }

  provisioner "local-exec" {
    command = <<EOT
      . /deployuser/scripts/exit_test.sh

      exit 0

      # create volatile storage
      ansible-playbook -i "$TF_VAR_inventory" ansible/softnas-ebs-disk.yaml --extra-vars "instance_id=${aws_instance.softnas1.*.id[count.index]} stop_softnas_instance=true mode=attach"; exit_test
      aws ec2 start-instances --instance-ids ${aws_instance.softnas1.*.id[count.index]}; exit_test
  
EOT

  }
}

resource "null_resource" "shutdown-softnas" {
  count = ( var.sleep && var.softnas_storage ) ? 1 : 0

  triggers = {
    instanceid = "${join(",", aws_instance.softnas1.*.id)}"
  }

  provisioner "local-exec" {
    #command = "aws ec2 stop-instances --instance-ids ${aws_instance.softnas1.id}"

    command = <<EOT
      . /deployuser/scripts/exit_test.sh

      exit 0

      aws ec2 stop-instances --instance-ids ${aws_instance.softnas1.*.id[count.index]}; exit_test
      # delete volatile storage
      ansible-playbook -i "$TF_VAR_inventory" ansible/softnas-ebs-disk.yaml --extra-vars "instance_id=${aws_instance.softnas1.*.id[count.index]} stop_softnas_instance=true mode=destroy"; exit_test
  
EOT

  }
}

resource "null_resource" "attach_local_mounts_after_start" {
  count      = ( !var.sleep && var.softnas_storage ) ? 1 : 0
  depends_on = [null_resource.start-softnas]

  #,"null_resource.mount_volumes_onsite"]

  triggers = {
    instanceid = "${join(",", aws_instance.softnas1.*.id)}"
    startsoftnas = "${join(",", null_resource.start-softnas.*.id)}"
    remote_mounts_on_local = var.remote_mounts_on_local
  }
  provisioner "remote-exec" {
    connection {
      user                = var.softnas_ssh_user
      host                = aws_instance.softnas1[0].private_ip
      bastion_host        = var.bastion_ip
      bastion_user        = "centos"
      private_key         = var.private_key
      bastion_private_key = var.private_key
      type                = "ssh"
      timeout             = "10m"
    }
    inline = [
      "set -x",
      "echo 'connection established'",
    ]
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      . /deployuser/scripts/exit_test.sh
      set -x

      exit 0

      echo "TF_VAR_remote_mounts_on_local= $TF_VAR_remote_mounts_on_local"
      # ensure routes on workstation exist
      if [[ $TF_VAR_remote_mounts_on_local == true ]] ; then
        printf "\n$BLUE CONFIGURE REMOTE ROUTES ON LOCAL NODES $NC\n"
        ansible-playbook -i "$TF_VAR_inventory" ansible/node-centos-routes.yaml -v -v --extra-vars "variable_host=workstation1 variable_user=deadlineuser hostname=workstation1 ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_private_ssh_key ethernet_device=$TF_VAR_workstation_ethernet_device"; exit_test
      fi
      # ensure volumes and pools exist after the disks were ensured to exist - this was done before starting instance.
      ansible-playbook -i "$TF_VAR_inventory" ansible/softnas-ebs-pool.yaml -v; exit_test
      #ensure exports are correct
      ansible-playbook -i "$TF_VAR_inventory" ansible/softnas-ebs-disk-update-exports.yaml -v --extra-vars "instance_id=${aws_instance.softnas1.*.id[count.index]}"; exit_test
      # mount volumes to local site when softnas is started
      if [[ $TF_VAR_remote_mounts_on_local == true ]] ; then
        printf "\n$BLUE CONFIGURE REMOTE MOUNTS ON LOCAL NODES $NC\n"
        # unmount volumes from local site - same as when softnas is shutdown, we need to ensure no mounts are present since existing mounts pointed to an incorrect environment will be wrong
        ansible-playbook -i "$TF_VAR_inventory" ansible/node-centos-mounts.yaml --extra-vars "variable_host=workstation1 variable_user=deadlineuser ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_private_ssh_key destroy=true variable_gather_facts=no" --skip-tags 'cloud_install local_install_onsite_mounts' --tags 'local_install'; exit_test
        # now mount current volumes
        ansible-playbook -i "$TF_VAR_inventory" ansible/node-centos-mounts.yaml -v -v --extra-vars "variable_host=workstation1 variable_user=deadlineuser ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_private_ssh_key" --skip-tags 'cloud_install local_install_onsite_mounts' --tags 'local_install'; exit_test
      fi
EOT
  }
}

output "attach_local_mounts_after_start" {
  value = null_resource.attach_local_mounts_after_start.*.id
}

resource "null_resource" "detach_local_mounts_after_stop" {
  count      = ( var.sleep && var.softnas_storage ) ? 1 : 0
  depends_on = [null_resource.shutdown-softnas]

  #,"null_resource.mount_volumes_onsite"]

  triggers = {
    instanceid = "${join(",", aws_instance.softnas1.*.id)}"
    startsoftnas = "${join(",", null_resource.shutdown-softnas.*.id)}"
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      . /deployuser/scripts/exit_test.sh
      set -x

      exit 0
      
      if [[ $TF_VAR_remote_mounts_on_local == true ]] ; then
        # unmount volumes from local site when softnas is shutdown.
        ansible-playbook -i "$TF_VAR_inventory" ansible/node-centos-mounts.yaml --extra-vars "variable_host=workstation1 variable_user=deadlineuser ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_private_ssh_key destroy=true variable_gather_facts=no" --skip-tags 'cloud_install local_install_onsite_mounts' --tags 'local_install'; exit_test
      fi
  
EOT

  }
}

