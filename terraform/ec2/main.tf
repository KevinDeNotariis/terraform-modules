data "template_file" "this" {
  template = file("${path.module}/templates/user-data.sh.tpl")

  vars = {
    cloudwatch_agent_json = jsonencode(jsondecode(file("${path.module}/conf/cloudwatch-agent.json")))
  }
}
