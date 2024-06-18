path "auth/token/lookup-self" {
  capabilities = ["read"]
}

path "auth/token/renew" {
  capabilities = ["update", "create"]
}

path "pki/issue/mtls" {
    capabilities = ["create", "update", "delete", "list", "read"]
    allowed_parameters = {
      "common_name" = ["server.seesquared.local"]
  }
}

path "pki/config/urls" {
    capabilities = ["read"]
}