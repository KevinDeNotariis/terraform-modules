output "ag_id" {
  value = aws_autoscaling_group.this.id
}

output "ag_launch_template_version" {
  value = aws_launch_template.this.latest_version
}

output "ag_ec2_instance_profile_arn" {
  value = aws_iam_instance_profile.this.arn
}

output "ag_ec2_instance_profile_name" {
  value = aws_iam_instance_profile.this.name
}

output "ag_ec2_sg_id" {
  value = aws_security_group.this.id
}

output "ag_ec2_iam_role_arn" {
  value = aws_iam_role.this.arn
}

output "ag_ec2_iam_role_name" {
  value = aws_iam_role.this.name
}
