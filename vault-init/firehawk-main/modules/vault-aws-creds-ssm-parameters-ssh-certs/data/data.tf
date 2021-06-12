data "aws_region" "current" {}
data "terraform_remote_state" "terraform_aws_sqs_vpn" { # read the arn with data.terraform_remote_state.packer_profile.outputs.instance_role_arn, or read the profile name with data.terraform_remote_state.packer_profile.outputs.instance_profile_name
  backend = "s3"
  config = {
    bucket = "state.terraform.${var.bucket_extension_vault}"
    key    = "init/modules/terraform-aws-sqs-vpn/terraform.tfstate"
    region = data.aws_region.current.name
  }
}