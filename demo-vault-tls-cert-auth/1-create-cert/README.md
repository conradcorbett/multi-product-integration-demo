## Using HCP Vault, create a certificate for Vault to use
vault secrets enable pki
vault write pki/root/generate/internal \
    common_name=seesquared.local \
    ttl=8760h
vault write pki/roles/vault \
    allowed_domains=seesquared.local \
    allow_subdomains=true \
    max_ttl=8760h
vault write -format=json pki/issue/vault \
common_name="vault-tls.seesquared.local" ip_sans="127.0.0.1" ttl=720h | jq -r .data > cert.json

## Store the certficate in HCP Vault
vault secrets enable -path=secret kv-v2
vault kv put secret/vault/cert @cert.json
vault kv get secret/vault/cert

## Create Vault policy to read from kv
vault policy write vault-cert vault-cert.hcl

## Some commands that may be helfpul if you need to work with jq, Don't use this otherwise though because it's using kv-v1
#vault write -format=json pki/issue/vault \
#common_name="vault-tls.seesquared.local" ip_sans="127.0.0.1" | tee \
#>(jq -r .data.certificate > vault-tls-certificate.pem) \
#>(jq -r .data.issuing_ca > vault-tls-issuing-ca.pem) \
#>(jq -r .data.private_key > vault-tls-private-key.pem)
#vault secrets enable -path="kv-v1" -description="Vault Certs" kv
#vault kv put kv-v1/vault/cert cert=@vault-tls-certificate.pem
#vault kv put kv-v1/vault/key key=@vault-tls-private-key.pem
#vault kv put kv-v1/vault/ca ca=@vault-tls-issuing-ca.pem
#vault kv get kv-v1/vault/cert



