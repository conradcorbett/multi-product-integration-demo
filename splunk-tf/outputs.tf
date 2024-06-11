output "test" {
  value = data.consul_service.demo-vault_service.service
}