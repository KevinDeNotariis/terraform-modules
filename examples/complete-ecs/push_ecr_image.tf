resource "null_resource" "build_and_push_ecr_image" {
  provisioner "local-exec" {
    command = "chmod +x build_and_push_ecr_image.sh && ./build_and_push_ecr_image.sh ${data.aws_caller_identity.current.account_id} ${data.aws_region.current.name} ${module.ecs.ecr_repo_url}"
  }

  depends_on = [
    module.ecs
  ]
}
