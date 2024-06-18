# NOMAD_ADDR & NOMAD_TOKEN found in output of workspace 6
## Deploy Vault
nomad run 1-demo-vault.nomad.hcl
set mac osx /etc/hosts file with Nomad external IP to resolve to vault-tls.seesquared.local
VAULT_IP=nomad node status -json $(nomad node pool nodes -json x86 | jq -r ".[0].ID") | jq -r '.Attributes."unique.platform.aws.public-ipv4"'
export VAULT_ADDR=https://vault-tls.seesquared.local:8204
export VAULT_TOKEN="vault_token_here"
vault audit enable file file_path=/vault/logs/vault-audit.log
vault write sys/internal/counters/config enabled=enable


## Deploy Splunk and Fluentd
nomad run 2-demo-splunkv2.nomad.hcl 
## Get Splunk url
echo https://$(nomad node status -json $(nomad node pool nodes -json x86 | jq -r ".[0].ID") | jq -r '.Attributes."unique.platform.aws.public-ipv4"'):8443
nomad run 3-demo-fluentd.nomad.hcl

vault auth enable cert

## Use HCP Vault to create a client cert! Make sure to use HCP VAULT!
### From the 1-create-cert terminal prompt:
mkdir ../2-deploy-jobs/client1
vault write -format=json pki/issue/vault \
common_name="vault-client1.seesquared.local" ttl=72h | tee \
>(jq -r .data.certificate > ../2-deploy-jobs/client1/certificate.pem) \
>(jq -r .data.issuing_ca > ../2-deploy-jobs/client1/issuing-ca.pem) \
>(jq -r .data.private_key > ../2-deploy-jobs/client1/private-key.pem)
### Client 2
mkdir ../2-deploy-jobs/client2
vault write -format=json pki/issue/vault \
common_name="vault-client2.seesquared.local" ttl=72h | tee \
>(jq -r .data.certificate > ../2-deploy-jobs/client2/certificate.pem) \
>(jq -r .data.issuing_ca > ../2-deploy-jobs/client2/issuing-ca.pem) \
>(jq -r .data.private_key > ../2-deploy-jobs/client2/private-key.pem)

## Switch to Vault running on nomad
### From 2-deploy-jobs terminal prompt:
vault auth enable cert
vault policy write vault-cert vault-cert.hcl
vault write auth/cert/certs/client1 display_name=client1 policies=vault-cert certificate=@client1/certificate.pem
vault login -method=cert -client-cert=client1/certificate.pem -client-key=client1/private-key.pem name=client1
VAULT_TOKEN=hvs.CAESINPo_YdqleKwr7BF8YANvb75Fc6oFVnQ6pQD1hGhOdgTGh4KHGh2cy43VG4zUklTREdCbUl0aEs2TU5LME5hQWU vault secrets list
### Client 2
vault write auth/cert/certs/client2 display_name=client2 policies=vault-cert certificate=@client2/certificate.pem
vault login -method=cert -client-cert=client2/certificate.pem -client-key=client2/private-key.pem name=client2
VAULT_TOKEN=hvs.CAESIFGziTLSeYsSFhSdqTlKSYCz54H3HtSK6_3flE8zpZWPGh4KHGh2cy5kVmtVNk1jWmNncml6aVhpejc5TTNuTjI vault secrets list
### Client 3
vault write auth/cert/certs/client3 display_name=client3 policies=vault-cert certificate=@client1/certificate.pem
vault login -method=cert -client-cert=client1/certificate.pem -client-key=client1/private-key.pem name=client3
VAULT_TOKEN=hvs.CAESIEuOKZZGxdo67uaE55aqDOjxiXe9ea184uVxkZE3L82zGh4KHGh2cy55VXlIaEI2UGxmY1NWaDFHYWRxeEpPMEg vault secrets list

### When setting up cert auth, you can configure with the issuing-ca cert, or you can use a specific cert. If you use issuing-ca, then any certs signed by that CA will be allowed to authenticate to Vault by default. To allow only specific common names, then set allowed_common_names, for example: 
vault write auth/cert/certs/client2 allowed_common_names=vault-client2.seesquared.local

### Each cert auth role that is created (vault write auth/cert/certs/ROLE) will use a client license. If you allow many common names under a single role, it still only uses a single client.
