path "auth/token/lookup-self" {
  capabilities = ["read"]
}

path "auth/token/renew" {
  capabilities = ["update", "create"]
}

path "*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}