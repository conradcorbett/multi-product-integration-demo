#output "vault_env_vars" {
#  value = nonsensitive("export VAULT_ADDR=${data.terraform_remote_state.nomad_cluster.outputs.nomad_public_endpoint} && export NOMAD_TOKEN=${data.vault_kv_secret_v2.bootstrap.data["SecretID"]}")
#}
#

output "test" {
  value = data.nomad_node_pool.x86.meta.nodes.address
}