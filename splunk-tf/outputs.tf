output "vault_env_vars" {
  value = nonsensitive("export VAULT_ADDR=http://${data.aws_instance.nomad_x86_client.public_ip}:8204 && export VAULT_TOKEN=${data.vault_kv_secret_v2.vault-dev-root-token.data["VAULT_ROOT_TOKEN"]}")
}

output "splunk_UI" {
  value = "https://${data.aws_instance.nomad_x86_client.public_ip}:8443"
}