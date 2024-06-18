#!/bin/bash
# Get HCP Vault token and URL from UI
export VAULT_TOKEN="hvs.CAESIKYye9z6HylN3RSJu1Yn5dmnqaEIgMdhV4Xctoq_jW1xGicKImh2cy5HZDUybklvR25JeVZUSXViOU1lZjRvY0guNUkyVGgQogM"
export VAULT_ADDR="https://cc-vault-cluster-public-vault-c8a47190.b9972b9f.z1.hashicorp.cloud:8200"
export VAULT_NAMESPACE="admin"

vault secrets enable pki

vault write pki/root/generate/internal common_name=seesquared.local ttl=8760h

vault write pki/config/urls \
    issuing_certificates="https://vault.seesquared.local:8200/v1/pki/ca" \
    crl_distribution_points="http://vault.seesquared.local/v1/pki/crl"

vault write pki/roles/mtls \
    allowed_domains=seesquared.local \
    allow_subdomains=true \
    max_ttl=1h

vault policy write pki-policy-server pki_server.hcl
vault policy write pki-policy-client pki_client.hcl

vault token create -policy=pki-policy-server -format=json \
    | jq -r ".auth.client_token" > vault_server.txt
vault token create -policy=pki-policy-client -format=json \
    | jq -r ".auth.client_token" > vault_client.txt
