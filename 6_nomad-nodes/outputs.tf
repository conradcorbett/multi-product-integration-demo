output "nomad_client_x86_asg" {
  value = aws_autoscaling_group.nomad_client_x86_asg.arn
}

#output "nomad_client_arm_asg" {
#  value = aws_autoscaling_group.nomad_client_arm_asg.arn
#}

output "nomad_env_vars" {
  value = nonsensitive("export NOMAD_ADDR=${data.terraform_remote_state.nomad_cluster.outputs.nomad_public_endpoint} && export NOMAD_TOKEN=${data.vault_kv_secret_v2.bootstrap.data["SecretID"]}")
}