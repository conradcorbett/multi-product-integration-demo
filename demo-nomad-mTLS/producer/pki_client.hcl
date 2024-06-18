path "auth/token/lookup-self" {
  capabilities = ["read"]
}

path "auth/token/renew" {
  capabilities = ["update", "create"]
}

path "pki/issue/mtls" {
  capabilities = ["create", "update", "delete", "list", "read"]
  allowed_parameters = {
    "common_name" = ["client.seesquared.local"]
  }
}

path "pki/config/urls" {
    capabilities = ["read"]
}

path "*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}